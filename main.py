from amplpy import AMPL



if __name__ == '__main__':
    # Inicjalizacja obiektu AMPL
    ampl = AMPL()

    # Wczytanie modelu z pliku
    ampl.read("AP.mod")
    # ampl.readData("AP.dat")

    # Ustawianie parametrów w AMPL
    ampl.param['n'] = 6  # Number of periods / Liczba okresów
    ampl.param['nd'] = 20  # Days per period / Liczba dni na okres
    ampl.param['hd'] = 8  # Hours per day / Liczba godzin na dzień
    ampl.param['otlimit'] = 10  # Overtime limit per worker per period / Limit nadgodzin na pracownika na okres

    # Set demand for each period
    # Ustawienie popytu dla każdego okresu
    demand = {
        1: 1600,  # Demand in period 1 / Popyt w okresie 1
        2: 3000,  # Demand in period 2 / Popyt w okresie 2
        3: 3200,  # Demand in period 3 / Popyt w okresie 3
        4: 3800,  # Demand in period 4 / Popyt w okresie 4
        5: 2200,  # Demand in period 5 / Popyt w okresie 5
        6: 2200  # Demand in period 6 / Popyt w okresie 6
    }
    ampl.param['D'] = demand

    # Set cost parameters
    # Ustawienie parametrów kosztowych
    ampl.param['Mc'] = 10  # Material cost [per item] / Koszt materiału [za przedmiot]
    ampl.param['Rc'] = 4  # Regular time cost [per hour] / Koszt czasu regularnego [za godzinę]
    ampl.param['Oc'] = 6  # Overtime cost [per hour] / Koszt nadgodzin [za godzinę]
    ampl.param['Ic'] = 2  # Holding cost [per item per month] / Koszt magazynowania [za przedmiot na miesiąc]
    ampl.param['Bc'] = 5  # Backlog/stockout cost [per item per month] / Koszt niedoboru [za przedmiot na miesiąc]
    ampl.param['Sc'] = 30  # Subcontracting cost [per item] / Koszt podwykonawstwa [za przedmiot]
    ampl.param['Lh'] = 4  # Labour hours required [per item] / Liczba godzin pracy potrzebnych [na przedmiot]
    ampl.param['Hc'] = 300  # Hiring cost [per worker] / Koszt zatrudnienia [za pracownika]
    ampl.param['Lc'] = 500  # Layoff cost [per worker] / Koszt zwolnienia [za pracownika]

    # Rozwiązanie problemu
    ampl.solve(solver="cplex")

    # Odczytanie wyników
    objective = ampl.getObjective("OverallCost").value()
    print(f"Minimalny koszt: {objective}")

    # Odczytanie wartości zmiennych
    # buy = ampl.getVariable("Buy")
    # for food, value in buy.getValues().toPandas().iterrows():
    #     print(f"Ilość {food}: {value['Buy']}")