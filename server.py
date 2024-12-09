from flask import Flask, request, jsonify
from flask_restx import Api, Resource, fields
from flask_cors import CORS
from amplpy import AMPL

app = Flask(__name__)
CORS(app)

api = Api(app, version="1.0", title="AMPL Solver API",
          description="API for solving AMPL optimization models using provided parameters.")

# Define namespace
ns = api.namespace('solver', description="AMPL Solver operations")

# Define the Swagger model for input parameters
input_model = api.model('SolveParameters', {
    'n': fields.Integer(required=True, description="Number of periods", default=6),
    'nd': fields.Integer(required=True, description="Days per period", default=20),
    'hd': fields.Integer(required=True, description="Hours per day", default=8),
    'otlimit': fields.Integer(required=True, description="Overtime limit per worker per period", default=10),
    'D': fields.Raw(required=True, description="Demand per period (e.g., {1: 1600, 2: 3000, ...})", default={1: 1600, 2: 3000, 3: 3200, 4: 3800, 5: 2200, 6: 2200}),
    'Mc': fields.Float(required=True, description="Material cost per item", default=10),
    'Rc': fields.Float(required=True, description="Regular time cost per hour", default=4),
    'Oc': fields.Float(required=True, description="Overtime cost per hour", default=6),
    'Ic': fields.Float(required=True, description="Holding cost per item per month", default=2),
    'Bc': fields.Float(required=True, description="Backlog/stockout cost per item per month", default=5),
    'Sc': fields.Float(required=True, description="Subcontracting cost per item", default=30),
    'Lh': fields.Float(required=True, description="Labour hours required per item", default=4),
    'Hc': fields.Float(required=True, description="Hiring cost per worker", default=300),
    'Lc': fields.Float(required=True, description="Layoff cost per worker", default=500),

    'W0': fields.Integer(required=False, description="Initial workforce", default=80),
    'S0': fields.Integer(required=False, description="Initial stockout/backlog", default=0),
    'I0': fields.Integer(required=False, description="Initial inventory", default=1000),
    'In': fields.Integer(required=False, description="Ending inventory", default=500),
    'Sn': fields.Integer(required=False, description="Ending stockout/backlog", default=0),

})

# Define the endpoint with Swagger documentation
@ns.route('/solve')
class SolveAMPL(Resource):
    @ns.expect(input_model)
    @ns.response(200, 'Success')
    @ns.response(400, 'Validation Error')
    @ns.response(500, 'Solver Error')
    def post(self):
        data = request.json

        # Initialize AMPL
        ampl = AMPL()
        ampl.read("AP.mod")

        # Required parameters
        ampl.param['n'] = data['n']     # Number of periods / Liczba okresów
        ampl.param['nd'] = data['nd']   # Days per period / Liczba dni na okres
        ampl.param['hd'] = data['hd']   # Hours per day / Liczba godzin na dzień
        ampl.param['otlimit'] = data['otlimit'] # Overtime limit per worker per period / Limit nadgodzin na pracownika na okres

        ampl.param['D'] = {int(k): v for k, v in data['D'].items()}     # Ustawienie popytu dla każdego okresu

        ampl.param['Mc'] = data['Mc']   # Material cost [per item] / Koszt materiału [za przedmiot]
        ampl.param['Rc'] = data['Rc']   # Regular time cost [per hour] / Koszt czasu regularnego [za godzinę]
        ampl.param['Oc'] = data['Oc']   # Overtime cost [per hour] / Koszt nadgodzin [za godzinę]
        ampl.param['Ic'] = data['Ic']   # Holding cost [per item per month] / Koszt magazynowania [za przedmiot na miesiąc]
        ampl.param['Bc'] = data['Bc']   # Backlog/stockout cost [per item per month] / Koszt niedoboru [za przedmiot na miesiąc]
        ampl.param['Sc'] = data['Sc']   # Subcontracting cost [per item] / Koszt podwykonawstwa [za przedmiot]
        ampl.param['Lh'] = data['Lh']   # Labour hours required [per item] / Liczba godzin pracy potrzebnych [na przedmiot]
        ampl.param['Hc'] = data['Hc']   # Hiring cost [per worker] / Koszt zatrudnienia [za pracownika]
        ampl.param['Lc'] = data['Lc']   # Layoff cost [per worker] / Koszt zwolnienia [za pracownika]

        # Set boundary conditions (optional)
        W0 = data.get('W0', 80)         # Liczba pracowników na początku
        S0 = data.get('S0', 0)          # Brak zaległości na początku
        I0 = data.get('I0', 1000)       # Początkowe zapasy
        In = data.get('In', 500)        # Zapasy na końcu okresu
        Sn = data.get('Sn', 0)          # Brak zaległości na końcu

        ampl.eval(f"param W0 := {W0};")
        ampl.eval(f"param S0 := {S0};")
        ampl.eval(f"param I0 := {I0};")
        ampl.eval(f"param In := {In};")
        ampl.eval(f"param Sn := {Sn};")

        ampl.eval("cW0: W[0] = W0;")
        ampl.eval("cS0: S[0] = S0;")
        ampl.eval("cI0: I[0] = I0;")
        ampl.eval("cIn: I[n] = In;")
        ampl.eval("cSn: S[n] = Sn;")

        # Solve the problem
        try:
            ampl.solve(solver="cplex")
        except Exception as e:
            return {'error': str(e)}, 500

        # Get results
        try:
            objective_value = ampl.getObjective("OverallCost").value()
            results = {'OverallCost': objective_value}

            # Extract variables
            for var_name in ['W', 'S', 'P', 'C', 'O', 'H', 'L', 'I']:
                var = ampl.getVariable(var_name).getValues().toDict()
                results[var_name] = var

        except Exception as e:
            return {'error': f"Error retrieving results: {str(e)}"}, 500
        return jsonify(results)


if __name__ == '__main__':
    app.run(debug=True)