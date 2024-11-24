# PARAMETERS

#liczba okresów
param n;
# Demand
param D{1..n};
# days per period [d/P]
param nd;
# hours per day [h/d]
param hd;
# allowed hours overtime/worker/period [h/worker/P]
param otlimit; 
# labour hours required per item [h/item]
param Lh; 
# Costs
param Mc; # Material cost [item]
param Rc; # Regular time cost [h]
param Oc; # Overtime cost [h]
param Ic; # Holding cost [item/period]
param Bc; # Backlog/stockout cost [item/period]
param Sc; # Subcontracting cost [item]
param Hc; # Hiring cost [worker]
param Lc; # Layoff cost [worker]

# DECISION VARIABLES

var W{0..n} integer >=0; # Workforce at period [i]                                                            [worker/P]
var S{0..n} integer >=0; # Items not delivered in Periond [i] carried over to Period [i+1]        [item/P]
var P{1..n} integer >=0; # Items produced in Period [i]                                                      [item/P]
var C{1..n} integer >=0; # Items subcontracted in Period [i]                                               [item/P]

var O{1..n} integer >=0; # Overtime hours per period                                                         [h/P]
var H{1..n} integer >=0; # Workers hired per period                                                          [worker/P]
var L{1..n} integer >=0; # Workers laid off  per period                                                      [worker/P]
var I{0..n} integer >=0; # Inventory in shop per period                                                      [items/P]

# OBJECTIVE FUNCTION

minimize OverallCost: sum{i in 1..n}(Rc*hd*nd*W[i] + Oc*O[i] + Hc*H[i] + Lc*L[i] + Ic*I[i] + Bc*S[i] + Mc*P[i] + Sc*C[i]);


# CONSTRAINTS
cW{i in 1..n}: W[i] = W[i-1]+H[i]-L[i]; # Workforce constraint
cP{i in 1..n}: P[i] <= hd/Lh*nd*W[i]+O[i]/Lh; # Production constraint 
cD{i in 1..n}: I[i-1]+P[i]+C[i] = D[i]+S[i-1]+I[i]-S[i]; # Demand constraint
cO{i in 1..n}: O[i] <= otlimit*W[i]; # Overtime workers constraint: Only up to 10 hours of overtime allowed per worker per period 

# BOUNDARY CONDITIONS
# Initial values
cW0: W[0] = 80;
cS0: S[0] = 0;
cI0: I[0] = 1000;
# End values
cIn: I[n] = 500;
cSn: S[n] = 0;

solve;
display OverallCost, sum{i in 1..6}D[i], sum{i in 1..6}P[i], S, P, C, D, W, O, H, L, I;

data;

# number od periods  [number]
param n:= 6; 
# days per period  [number]
param nd:= 20; 
# hours per day [h/day]
param hd:= 8;
# overtime per worker per period allowed [h/worker/P]
param otlimit:= 10; # [number]
# Demand each period
param D := 1 1600 2 3000 3 3200 4 3800 5 2200 6 2200;
# COST Parameters
param Mc:= 10; # Material cost [item]
param Rc:= 4; # Regular time cost [h]
param Oc:= 6; # Overtime cost [h]
param Ic:= 2; # Holding cost [item/month]
param Bc:= 5; # Backlog/stockout cost [item/month]
param Sc:= 30; # Subcontracting cost [item]
param Lh:= 4; # Labour hours required [item]
param Hc:= 300; # Hiring cost [worker]
param Lc:= 500; # Layoff cost [worker]

end;