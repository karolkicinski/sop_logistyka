# =========> PARAMETRY

param n;                # Liczba okresów [liczba]
param D{1..n};          # Popyt na produkty w każdym okresie [jednostki/okres]
param nd{1..n};         # Liczba dni w danym okresie [dni/okres]
param hd;               # Liczba godzin pracy na dzień [godziny/dzień]
param otlimit;          # Maksymalna liczba nadgodzin dozwolonych na pracownika w jednym okresie [godziny/pracownik/okres]
param Lh;               # Liczba godzin pracy potrzebna do wyprodukowania jednego produktu [godziny/jednostka]

# =========> KOSZTY

param Mc;       # Koszt materiału na jednostkę [waluta/jednostka]
param Rc;       # Koszt regularnego czasu pracy na godzinę [waluta/godzina]
param Oc;       # Koszt nadgodzin na godzinę [waluta/godzina]
param Ic;       # Koszt magazynowania na jednostkę na okres [waluta/jednostka/okres]
param Bc;       # Koszt niedoboru/magazynowania na jednostkę na okres [waluta/jednostka/okres]
param Sc;       # Koszt podwykonawstwa na jednostkę [waluta/jednostka]
param Hc;       # Koszt zatrudnienia jednego pracownika [waluta/pracownik]
param Lc;       # Koszt zwolnienia jednego pracownika [waluta/pracownik]

# =========> ZMIENNE DECYZYJNE

var W{0..n} integer >=0;    # Liczba pracowników w danym okresie [pracownicy/okres]
var S{0..n} integer >=0;    # Niedostarczone produkty w okresie i, przeniesione do okresu i+1 [jednostki/okres]
var P{1..n} integer >=0;    # Liczba wyprodukowanych jednostek w okresie i [jednostki/okres]
var C{1..n} integer >=0;    # Liczba jednostek wyprodukowanych przez podwykonawców w okresie i [jednostki/okres]
var O{1..n} integer >=0;    # Liczba nadgodzin w okresie i [godziny/okres]
var H{1..n} integer >=0;    # Liczba nowo zatrudnionych pracowników w okresie i [pracownicy/okres]
var L{1..n} integer >=0;    # Liczba zwolnionych pracowników w okresie i [pracownicy/okres]
var I{0..n} integer >=0;    # Zapasy w sklepie w okresie i [jednostki/okres]

# =========> FUNKCJA CELU

minimize OverallCost: sum{i in 1..n}(Rc*hd*nd[i]*W[i] + Oc*O[i] + Hc*H[i] + Lc*L[i] + Ic*I[i] + Bc*S[i] + Mc*P[i] + Sc*C[i]);
# Koszt regularnej pracy + Koszt nadgodzin + Koszt zatrudnienia + Koszt zwolnień + Koszt magazynowania + Koszt niedoborów + Koszt materiałów + Koszt podwykonawstwa

# Rachunek jednostek dla każdego składnika:

    # Koszt regularnego czasu pracy (Rc * hd * nd[i] * W[i]):
    # [waluta/godzina] * [godziny/dzień] * [dni/okres] * [pracownicy/okres] = [waluta/okres]

    # Koszt nadgodzin (Oc * O[i]):
    # [waluta/godzina] * [godziny/okres] = [waluta/okres]

    # Koszt zatrudnienia (Hc * H[i]):
    # [waluta/pracownik] * [pracownicy/okres] = [waluta/okres]

    # Koszt zwolnienia (Lc * L[i]):
    # [waluta/pracownik] * [pracownicy/okres] = [waluta/okres]

    # Koszt magazynowania (Ic * I[i]):
    # [waluta/jednostka/okres] * [jednostki/okres] = [waluta/okres]

    # Koszt niedoboru (Bc * S[i]):
    # [waluta/jednostka/okres] * [jednostki/okres] = [waluta/okres]

    # Koszt materiałów (Mc * P[i]):
    # [waluta/jednostka] * [jednostki/okres] = [waluta/okres]

    # Koszt podwykonawstwa (Sc * C[i]):
    # [waluta/jednostka] * [jednostki/okres] = [waluta/okres]

    # Wynik całkowity:
    # Funkcja celu zwraca wartość w [waluta/okres].


# OGRANICZENIA (CONSTRAINTS)

    # Liczba pracowników w okresie i zależy od liczby pracowników w poprzednim okresie oraz zatrudnień i zwolnień
    # [pracownicy/okres] = [pracownicy/okres] + [pracownicy/okres] - [pracownicy/okres]

cW{i in 1..n}: W[i] = W[i-1]+H[i]-L[i];

    # Produkcja w okresie i jest ograniczona czasem pracy
    # [jednostki/okres] <= ([godziny/dzień] / [godziny/jednostka]) * [dni/okres] * [pracownicy/okres] + ([godziny/okres] / [godziny/jednostka])
    # [jednostki/okres] <= [jednostki/okres] + [jednostki/okres]

cP{i in 1..n}: P[i] <= hd/Lh*nd[i]*W[i]+O[i]/Lh;

    # Równowaga między popytem, produkcją, podwykonawstwem i zapasami
    # [jednostki/okres] + [jednostki/okres] + [jednostki/okres] = [jednostki/okres] + [jednostki/okres] + [jednostki/okres] - [jednostki/okres]

cD{i in 1..n}: I[i-1]+P[i]+C[i] = D[i]+S[i-1]+I[i]-S[i];

    # Nadgodziny są ograniczone przez liczbę pracowników i limit nadgodzin
    # [godziny/okres] <= ([godziny/pracownik/okres] * [pracownicy/okres])

cO{i in 1..n}: O[i] <= otlimit*W[i];