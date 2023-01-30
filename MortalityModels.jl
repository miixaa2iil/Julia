ENV["GKS_ENCODING"] = "utf8"

using CSV, DataFrames # wczytanie csv i ramki danych

using Plots, Plots.PlotMeasures, StatsPlots # wykresy

using StringEncodings #?

#using FreqTable

#using Plotly
# doczytać w Plots i można domyślny backend

using GLM, StatsModels, HypothesisTests, StatsKit, Statistics #?

using Formatting

using CategoricalArrays # faktory

#using LegacyStrings

using RegressionTables # do LaTeXa

using DecisionTree# drzewa decyzyjne

# dane

#dane, rysunki, wyniki = ("sciezka/").*("dane/", "rysunki/", "wyniki/")

udaryRoz = CSV.File(dane*"udary2018Roz.csv") |> DataFrame # wiecej danych

ile_szpitali = CSV.File(dane*"powiaty_udarowe.csv") |> DataFrame # dane

# przerwarzanie
f = "%07d"
w = "%02d"
p = "%04d"
lista_woj = ["dolnośląskie", "kujawsko-pomorskie", "lubelskie", "lubuskie", "łódzkie", "małopolskie", "mazowieckie", "opolskie", "podkarpackie", "podlaskie", "pomorskie", "śląskie", "świętokrzyskie", "warmińsko-mazurskie", "wielkopolskie", "zachodniopomorskie"]
#udaryRoz[!, :PELNY_TERYT_PACJ |> x -> sprintf1(f, x)]
udaryRoz[!, :PELNY_TERYT_PACJ] = sprintf1.(f, udaryRoz.PELNY_TERYT_PACJ)
udaryRoz[!, :PELNY_TERYT_KOMORKI] = sprintf1.(f, udaryRoz.PELNY_TERYT_KOMORKI)
#udaryRoz
ile_szpitali[:liczba_udarowych] = string.(ile_szpitali.liczba)
ile_szpitali[:pow_pacj] = sprintf1.("%04d", ile_szpitali.TERYT)

udary = join(udary, select(udaryRoz, [:ID_PACJ, :WIEK, :PELNY_TERYT_PACJ, :PELNY_TERYT_KOMORKI]), on = :ID_PACJ, kind = :left)

udary[:woj_pacj] = map(x -> x[1:2], udary.PELNY_TERYT_PACJ) |> x -> replace(x, "02" => "dolnośląskie", "04" => "kujawsko-pomorskie", "06" => "lubelskie", "08" => "lububskie", "10" => "łódzkie", "12" => "małopolskie", "14" => "mazowieckie", "16" => "opolskie", "18" => "podkarpackie", "20" => "podlaskie", "22" => "pomorskie", "24" => "śląskie", "26" => "świętokrzyskie", 28 => "warmińsko-mazurskie", "30" => "wielkopolskie", "32" => "zachodniopomorskie")

udary[:pow_pacj] =map(x -> x[1:4], udary.PELNY_TERYT_PACJ)

udary[:pow_komorki] = map(x -> x[1:4], udary.PELNY_TERYT_KOMORKI)

udary[:gmina_pacj]  = map(x -> string(x[end]), udary.PELNY_TERYT_PACJ) |> y -> replace(y, "1" => "miejska", "2" => "wiejska", "3"=> "miejsko-wiejska", "4" => "miasto w miejsko-wiejskiej", "5" => "wsie w miejsko-wiejskiej", "8" => "miejska", "9" => "miejska")

udary.gmina_pacj

udary[:pow_grodzki] = map(x -> x[3:4] > "61", udary.PELNY_TERYT_PACJ)

udary[udary.pow_grodzki, :gmina_pacj] = "miasto npp."

udary[:czySlaskie] = udary.woj_pacj .== "śląskie"

udary[:czyWies] = udary.gmina_pacj .== "wiejska"

# zapis
#udary |> CSV.write(dane*"udary_juliowe.csv")
# juz przerobione
udary = CSV.File(dane*"udary_juliowe.csv") |> DataFrame

udary[!, :czyPowiat] = map(x -> Bool(x), udary.czyPowiat) # i wtedy jest Bool a nie BitArray

udary[!, :pow_pacj] = sprintf1.(p, udary.pow_pacj)

udary[!, :pow_komorki] = sprintf1.(p, udary.pow_komorki)

#udary[!, :czyPowiat] = Bool.(udary.czyPowiat)
#udary[!, :pochodzenie] = ifelse.(udary.pow_grodzki .& udary.czyPowiat, "leczony w swoim powiecie grodzkim", ifelse.(udary.pow_grodzki .& .!udary.czyPowiat, "leczony poza swoim powiatem grodzkim", ifelse.(udary.czyPowiat .& udary.czyWies, "leczony w swoim powiecie z gminy wiejskiej", ifelse.(udary.czyPowiat .& udary.czyWies, "leczony w swoim powiecie nie z gminy wiejskiej", ifelse.(.!udary.czyPowiat .& udary.czyWies, "leczony spoza swojego powiaty i z gminy wiejskiej", "leczony spoza swojego powiatu i nie z gminy wiejskiej")))))

#udary[!, :woj_pacj] = sprintf1.(w, woj_komorki)

pojezierze = ["2001"; "2009"; "2805"; "2818"; "2813"; "2806"; "2819"; "2816"; "2817"; "	2810"; "2862"; "2814"; "2815"; "2807"]

udary[!, :czyJeziora] = in.(udary.pow_pacj, (pojezierze, ))

gory = ["0210"; "0206"; "0212"; "0261"; "0207"; "0221"; "0265"; "0208"; "2402"; "2461"; "2403"; "2417"; "1215"; "1209"; "1207"; "1211"; "1210"; "1217"; "1205"; "1262"; "1805"; "1807"; "1817"; "1821"; "1801"; "1813"]

#gory_csv = DataFrame(TERYT = gory)

#gory_csv |> CSV.write(dane*"gory.csv")
udary[!, :czyGory] = in.(udary.pow_pacj, (gory,))
GOP = ["2401"; "2414"; "2405"; "2408"; "2412"; "2413"; "2462"; "2463"; "2465"; "2466"; "2467"; "2468"; "2469"; "2470"; "2471"; 	"2472"; "2473"; "2474"; "2475"; "2476"; "2477"; "2478"; "2479"]
# rysunki
#gop_csv = DataFrame(TERYT = GOP)

#gop_csv |> CSV.write(dane*"gop.csv")
udary[!, :czyGOP] = in.(udary.pow_pacj, (GOP,))


udary = udary[udary.oddzialUdar .!= "trombo", :]
udary[!, :samOddzial] = ifelse.(udary.oddzialUdar .== "brak", "brak oddziału udarowego", ifelse.(in.(udary.oddzialUdar, (["nieBez" "nieZ"],)), "leczony poza udarowym", "leczony na udarowym"))
udary[!, :leczenie] = ifelse.(in.(udary.oddzialUdar, (["nieZ" "takZ"],)), true, false)

zgony = [:zgon007, :zgon030, :zgon090, :zgon365]
co
udary_zgon = by( udary[udary.oddzialUdar .!= "trombo", :], :oddzialUdar, (zgony .=> mean)..., sort=true)
nam = udary_zgon.oddzialUdar
ctg = ["zgon 365-dniowy" "zgon 90-dniowy" "zgon 30-dniowy" "zgon 7-dniowy"]
data = hcat(udary_zgon.zgon365_mean-udary_zgon.zgon090_mean,
            udary_zgon.zgon090_mean-udary_zgon.zgon030_mean,
            udary_zgon.zgon030_mean-udary_zgon.zgon007_mean,
            udary_zgon.zgon007_mean)
groupedbar(nam, 100data, bar_position = :stack,
foreground_color_legend = :lightgray,
background_color_legend = :lime,
foreground_color_grid = :lightgray,
tick_direction = :out,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
gridcolor = :black,
yticks = collect(0:7)*10,
minorticks =true,
           xlabel="typ oddziału leczenia wraz z trombolizą",
           ylabel="średnia śmiertelność [%]",
           legend=:topleft,

           label=ctg,
           color= ["#00FFFF" "#007FFF" "#0000FF" "	#6C3082"])
           savefig(rysunki*"oddzial_smiertelnosc.png")#["#6666ff" "#4444bb" "#222299" "#000055"])
OU = combine(groupby(udary, :oddzialUdar), nrow => "N")
OU[!, "P"] = OU.N/sum(OU.N)*100
# histogram wiek plec
#by(select(udary, [:PLEC, :WIEK]), :PLEC,  x -> describe(x, cols=:WIEK, :min, :q25, :median, :q75, :max, :mean, :std)) |> x -> select(x, Not(2)) |> to_tex
summarize_by(udary, :oddzialUdar, :WIEK, detail = true)

to_tex(summarize_by(udary, :PLEC, :WIEK, detail = true))
by(udary, :PLEC, :WIEK => mode)

@df unique(udary, :ID_PACJ) histogram(:WIEK,
group = :PLEC,
foreground_color_legend = :lightgray,
background_color_legend = :lime,
foreground_color_grid = :lightgray,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
gridcolor = :black,
#linecolor = :white,
color = [:red :blue],
label = ["kobiety" "mężczyźni"],
alpha = .75,
C
bar_position = :overlay,
xaxis = "wiek",
yaxis = "liczebność",
tick_direction = :out,
draw_arrow = true,
xticks = collect(0:11)*10,
yticks = collect(0:12)*100,
xwiden = false,
legend  = :topleft)
savefig(rysunki*"histogram_wiek_plec.png")

#format( 1234.5, mixedfractionsep = ",")

#FormatSpec("d")
udary_typy = CSV.File(dane*"podzial_udarow.csv") |> DataFrame

udary_typy[!, :icd10] = map(x -> x[1:3], udary_typy.ICD10_GL_HOSPIT)
pie(:ID_HOSPITALIZACJI, :icd10)

ciasto = combine(groupby(udary_typy, :icd10), nrow => "N")
gr()
@df sort(ciasto, :N ,rev = true) bar(:icd10, :N/1000,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
#bar_position = :overlay,
xaxis = "typ udaru",
yaxis = "liczebność [tys.]",
tick_direction = :out,
draw_arrow = true,
#xticks = collect(0:2:32),
yticks = collect(0:10:80),
ywiden = false,
legend = :none)
savefig(rysunki*"typy_udarow.png")
daty = udaryRoz[in.(udaryRoz.ID_PACJ, (udary.ID_PACJ,)), [:DATA_PRZYJECIA, :DATA_WYPISU]]
dlugosc_hospitalizacji = sort(Dates.value.(daty.DATA_WYPISU-daty.DATA_PRZYJECIA))

dlugosc_hospitalizacji = DataFrame(num = dlugosc_hospitalizacji)

dlugosc_hospitalizacji[!, :str] = dlugosc_hospitalizacji.num |> x -> ifelse.(isless.(x, 32), string.(x), "31+")

to_tex(summarize(dlugosc_hospitalizacji, :num, detail = true))
mode(dlugosc_hospitalizacji.num)

by(dlugosc_hospitalizacji, :str, nrow)
@df combine(groupby(dlugosc_hospitalizacji, :str), nrow => "N") bar(:str, :N/1000,
#foreground_color_grid = :lightgray,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
#bar_position = :overlay,
xaxis = "czas trwania hospitalizacji [dzień]",
yaxis = "liczebność [tys.]",
tick_direction = :out,
draw_arrow = true,
#xticks = collect(0:2:32),
xticks = 17,
yticks = collect(0:2.5:20),
ywiden = false,
legend  = :none
)
savefig(rysunki*"dlugosc_hosp.png")

daty2018 = daty[(daty.DATA_PRZYJECIA .> Date("2017-12-31")) .& (daty.DATA_PRZYJECIA .< Date("2019-01-01")), :]

@df combine(groupby(sort!(daty2018, :DATA_PRZYJECIA), :DATA_PRZYJECIA), nrow => "N") plot(:DATA_PRZYJECIA, :N,
#foreground_color_grid = :lightgray,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
#bar_position = :overlay,
xaxis = "data",
yaxis = "liczba nowych hospitalizacji",
tick_direction = :out,
draw_arrow = true,
#xticks = collect(0:2:32),
xticks = Date.(vcat("2018-".*["01", "03", "05", "07", "09", "11"].*"-01", "2019-01-01")),
yticks = collect(0:25:225),
ywiden = false,
legend  = :none
)
savefig(rysunki*"sezonowosc.png")
#gr()
sort!(udary, order(:WIEK)) # sortowanie po wieku

udary[!, :grWiekEks] = udary.grWiekEks |> x-> CategoricalArray(x, ordered = true)


# smiertelnosc_wiek_plec
grupa_wiek_plec = combine(groupby(udary, [:grWiekEks, :PLEC]),  zgony .=> x -> 100*mean(x))
#grupa_wiek_plec[!, :grWiekEks] = grupa_wiek_plec.grWiekEks |> string.()
grupa_wiek_plec[!, :grWiekEks] = map(x -> String(x), grupa_wiek_plec.grWiekEks)

@df grupa_wiek_plec plot(:grWiekEks, [:zgon007_function :zgon030_function :zgon090_function :zgon365_function],
group = :PLEC,
#foreground_color_legend = :lightgray,
background_color_legend = :lime,
#foreground_color_grid = :lightgray,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = repeat([:red :blue], inner = (1, 4)), #reshape(repeat([:blue :red], 4), (1,8)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
#markeralpha = 0.75,
seriescolor = repeat([:red :blue], inner = (1, 4)), #reshape(repeat([:blue :red], 4), (1,8)),
label = reshape((["kobiety" "mężczyźni"].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 8)),
#alpha = .75,
minorticks = true,
#bar_position = :overlay,
xaxis = "grupa wiekowa",
yaxis = "średnia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
yticks = collect(0:12)*5,
#xwiden = false,
legend  = :topleft
)
savefig(rysunki*"smiertelnosc_wiek_plec.png")

## sam wiek
udary[!, :grWiekEks] = map(x -> String(x), udary.grWiekEks)
wiek_plec = by(udary, [:WIEK, :PLEC],  zgony .=> x -> 100*mean(x))


@df wiek_plec plot(:WIEK, [:zgon007_function :zgon365_function],
group = :PLEC,
#foreground_color_legend = :lightgray,
background_color_legend = :lime,
#foreground_color_grid = :lightgray,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
#linestyle = :dot,
#linecolor = reshape(repeat([:blue :red], 4), (1,8)),
#lw = 1.5,
seriestype = :scatter,
markershape = [:star4 :star8],
seriescolor = reshape(repeat([:blue :red], 2), (1,4)),
label = reshape((["kobiety" "mężczyźni"].*[": zgon "]).*["7", "365"].*["-dniowy"], (1, 4)),
minorticks = true,
xaxis = "wiek",
yaxis = "śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :top
)


a = by(udary, [:grWiekEks, :liczba_udarowych],  zgony .=> x -> 100*mean(x))
@df a plot(:grWiekEks, [:zgon007_function :zgon365_function],
group = :liczba_udarowych,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
lw = 1.5,
markershape = [:star4 :star8],
markeralpha = 0.75,
alpha = .75,
minorticks = true,
xaxis = "wiek",
yaxis = "śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)

####
names(udary)
a = by(udary, [:grWiekEks, :gmina_pacj],  zgony .=> x -> 100*mean(x))
c = a.grWiekEks
d = c[end.-[5, 4, 3, 2, 1,0]]
e = c[1:(end-6)]
f = reshape(vcat(d, e), (1,36))
b = deepcopy(a)
a.ind = vcat(repeat(2:7, inner = 6), 1, 1)
b[:, :grWiekEks => Categorical]
@df a plot(:grWiekEks, :zgon365_function,
group = :gmina_pacj,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = [:blue :red :green :magenta :cyan :orange],
lw = 1.5,
alpha = .75,
minorticks = true,
xaxis = "wiek",
yaxis = "śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)

# powiat z wsia
powiat_wies = combine(groupby(udary, [:grWiekEks, :czyWies, :czyPowiat]),  zgony .=> x -> 100*mean(x))

@df powiat_wies plot(:grWiekEks, [:zgon007_function :zgon030_function :zgon090_function :zgon365_function],
group = (:czyWies, :czyPowiat),
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = repeat([:red :blue :orange :green], inner = (1, 4)),#reshape(repeat([:red :blue :orange :green], 4), (1,16)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
seriescolor = reshape(repeat([:red :blue :orange :green], 4), (1,16)),
label = reshape((["pP" "wP" "wPGW" "pPGW"].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 16)),
minorticks = true,
xaxis = "grupa wiekowa",
yaxis = "średnia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :outerright
)
savefig(rysunki*"powiat_wies.png")


pochodzenie = combine(groupby(udary, [:grWiekEks, :czyWies, :czyPowiat]), nrow => "N")

#pochodzenie[!, :nr] = map( x -> string(x[2]), pochodzenie.grWiekEks)
pochodzenie[!, :grWiekEks] = pochodzenie.grWiekEks |> x-> CategoricalArray(x,ordered = true)
poziomy = levels(pochodzenie.grWiekEks)

poziomy = vcat(poziomy[end], poziomy[1:end-1])
levels!(pochodzenie.grWiekEks , poziomy)
sort!(pochodzenie, :nr)
@df udary histogram(:WIEK,
group = (:czyWies, :czyPowiat),
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
alpha = .75,
seriescolor = [:red :blue :orange :green],
label = ["pP" "wP" "wPGW" "pPGW"],
yticks = collect(0:200:2000),
#xticks = (unique(pochodzenie.nr)  unique(pochodzenie.grWiekEks)),
xtick = collect(0:10:110),
xaxis = "wiek",
yaxis = "liczebność [tys.]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"histogram_wies.png")

powiat_grodzki = combine(groupby(udary, [:grWiekEks, :pow_grodzki, :czyPowiat]),  zgony .=> x -> 100*mean(x))

@df powiat_grodzki plot(:grWiekEks, [:zgon007_function],
group = (:pow_grodzki, :czyPowiat),
background_color_legend = :lime,
#legend_size = 10,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = [:red :blue :orange :green], #repeat([:red :blue :orange :green], inner = (1, 4)),#reshape(repeat([:red :blue :orange :green], 4), (1,16)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
#markeralpha = 0.75,
seriescolor = [:red :blue :orange :green], #reshape(repeat([:red :blue :orange :green], 4), (1,16)),
label = ["pP" "wP" "pPPG" "wPPG"].*": zgon 7-dniowy", #reshape((["pP" "wP" "wPPG" "pPPG"].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 16)),
minorticks = true,
xaxis = "grupa wiekowa",
yaxis = "średnia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"powiat_grodzki.png")

mieszczuchy = combine(groupby(udary, [:grWiekEks, :pow_grodzki, :czyPowiat]), nrow => "N")

#pochodzenie[!, :nr] = map( x -> string(x[2]), pochodzenie.grWiekEks)
mieszczuchy[!, :grWiekEks] = mieszczuchy.grWiekEks |> x-> CategoricalArray(x,ordered = true)
poziomy = levels(mieszczuchy.grWiekEks)

poziomy = vcat(poziomy[end], poziomy[1:end-1])
levels!(mieszczuchy.grWiekEks , poziomy)

@df udary histogram(:WIEK,
group = (:pow_grodzki, :czyPowiat),
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
alpha = .75,
seriescolor = [:red :blue :orange :green],
label = ["wP" "pP" "pPPG" "wPPG"],
yticks = collect(0:200:1600),
#xticks = (unique(pochodzenie.nr)  unique(pochodzenie.grWiekEks)),
xticks = collect(0:10:110),
xaxis = "wiek",
yaxis = "liczebność",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"histogram_grodzki.png")
liczebnosc_pacjentow = sort(udary[:, [:ID_PACJ, :lPacj]], :lPacj)

maks = maximum(udary.lPacj)
liczebnosc_pacjentow[!, :grLPacj] = cut(liczebnosc_pacjentow.lPacj, [0, 49, 99, 149, 249, 499, maks], extend = true) |> x -> string.(x)


@df combine(groupby(liczebnosc_pacjentow, :grLPacj), nrow => "N") bar(:grLPacj, :N/1000,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
yticks = collect(0:5:40),
xaxis = "przedział liczby rocznej pacjentów",
yaxis = "liczba pacjentów [tys.]",
tick_direction = :out,
draw_arrow = true,
legend  = :none
)
savefig(rysunki*"liczebnosc_pacjentow1.png")

liczebnosc_pacjentow = sort(udary[:, [:ID_PACJ, :lPacj]], :lPacj)

maks = maximum(udary.lPacj)
liczebnosc_pacjentow[!, :grLPacj] = cut(liczebnosc_pacjentow.lPacj, [0, 149, 249, 399, 549, maks], extend = true) |> x -> string.(x)


@df combine(groupby(liczebnosc_pacjentow, :grLPacj), nrow => "N") bar(:grLPacj, :N/1000,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
xaxis = "przedział liczby rocznej pacjentów",
yaxis = "liczba pacjentów",
tick_direction = :out,
draw_arrow = true,
legend  = :none
)
savefig(rysunki*"liczebnosc_pacjentow2.png")


liczebnosc_pacjentow = sort(udary[:, [:ID_PACJ, :lPacj]], :lPacj)

maks = maximum(udary.lPacj)
liczebnosc_pacjentow[!, :grLPacj] = cut(liczebnosc_pacjentow.lPacj, [0, 49, 99, 149, 249, 499, maks], extend = true) |> x -> string.(x)


@df combine(groupby(liczebnosc_pacjentow, :grLPacj), nrow => "N") bar(:grLPacj, :N/1000,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
yticks = collect(0:5:40),
xaxis = "przedział liczby rocznej pacjentów",
yaxis = "liczba pacjentów",
tick_direction = :out,
draw_arrow = true,
legend  = :none
)
savefig(rysunki*"liczebnosc_pacjentow1.png")

liczebnosc_pacjentow = sort(udary[:, [:ID_PACJ, :lPacj]], :lPacj)

maks = maximum(udary.lPacj)
print(describe(udary.lPacj))
udaryRoz.ID_SZPITALA |> length∘unique

liczba_szpitali = sort!(unique(select(join(select(udary, [:ID_PACJ, :lPacj]), select(udaryRoz, [:ID_PACJ, :ID_SZPITALA]), on = :ID_PACJ), [:ID_SZPITALA, :lPacj])), :lPacj)

liczba_szpitali[!, :grLPacj] = cut(liczba_szpitali.lPacj, [0, 5,  20, 50,  150, 250, 350, 500, 1000], extend = true) |> x -> string.(x)

@df combine(groupby(liczba_szpitali, :grLPacj), nrow => "N") bar(:grLPacj, :N,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
xaxis = "przedział liczby rocznej pacjentów",
yaxis = "liczba szpitali",
tick_direction = :out,
draw_arrow = true,
yticks = collect(0:9)*10,
legend  = :none
)
savefig(rysunki*"liczebnosc_szpitali")

szpitale = liczba_szpitali.ID_SZP |> length∘unique
@df combine(groupby(liczba_szpitali, :grLPacj), nrow => "N") bar(:grLPacj, :N,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
xaxis = "przedział liczby rocznej pacjentów",
yaxis = "liczba szpitali",
tick_direction = :out,
draw_arrow = true,
yticks = collect(0:9)*10,
legend  = :none
)
combine(groupby(udaryRoz, :ID_SZPITALA), nrow)
liczebnosc_pacjentow[!, :grLPacj] = cut(liczebnosc_pacjentow.lPacj, vcat(collect(0:100:600), 1000), extend = true) |> x -> string.(x)

pacjenci = udary.ID_PACJ |> length
combine(groupby(udaryRoz, :ID_SZPITALA), nrow)
@df combine(groupby(liczebnosc_pacjentow, :grLPacj), nrow => "N") bar(:grLPacj, :N/1000,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
minorticks = true,
xaxis = "przedział liczby rocznej pacjentów",
yaxis = "liczba pacjentów [tys.]",
tick_direction = :out,
draw_arrow = true,
yticks = collect(0:2.5:17.5),
legend  = :none
)
savefig(rysunki*"liczebnosc_pacjentow")

grupa_wiek_gop = combine(groupby(udary, [:grWiekEks, :czyGOP]),  zgony .=> x -> 100*mean(x))


powiat_wies = combine(groupby(udary, [:grWiekEks, :czyWies, :czyPowiat]),  zgony .=> x -> 100*mean(x))


@df grupa_wiek_gop plot(:grWiekEks, [:zgon007_function :zgon030_function :zgon090_function :zgon365_function],
group = :czyGOP,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = reshape(repeat([:blue :red], 4), (1,8)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
seriescolor = reshape(repeat([:blue :red], 4), (1,8)),
label = reshape((["pozostałe" "silnie zurbanizowane" ].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 8)),
minorticks = true,
xaxis = "grupa wiekowa",
yaxis = "średnia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"smiertelnosc_wiek_gop.png")

@df grupa_wiek_gory plot(:grWiekEks, [:zgon007_function :zgon030_function :zgon090_function :zgon365_function],
group = :czyGory,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = reshape(repeat([:blue :red], 4), (1,8)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
seriescolor = reshape(repeat([:blue :red], 4), (1,8)),
label = reshape((["bez gór" "góry"].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 8)),
minorticks = true,
xaxis = "wiek",
yaxis = "średnia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"smiertelnosc_wiek_gory.png")

grupa_wiek_pojezierze = by(udary, [:grWiekEks, :czyJeziora],  zgony .=> x -> 100*mean(x))

@df grupa_wiek_pojezierze plot(:grWiekEks, [:zgon007_function :zgon030_function :zgon090_function :zgon365_function],
group = :czyJeziora,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = reshape(repeat([:blue :red], 4), (1,8)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
seriescolor = reshape(repeat([:blue :red], 4), (1,8)),
label = reshape((["bez jezior" "jeziora"].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 8)),
minorticks = true,
xaxis = "wiek",
yaxis = "średnia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"histogram_wiek_jeziora.png")

grupa_wiek_gory = combine(groupby(udary, [:grWiekEks, :czyGory]),  zgony .=> x -> 100*mean(x))

@df grupa_wiek_gory plot(:grWiekEks, [:zgon007_function :zgon030_function :zgon090_function :zgon365_function],
group = :czyGory,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = reshape(repeat([:blue :red], 4), (1,8)),
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
seriescolor = reshape(repeat([:blue :red], 4), (1,8)),
label = reshape((["bez gór" "góry"].*[": zgon "]).*["7", "30", "90", "365"].*["-dniowy"], (1, 8)),
minorticks = true,
xaxis = "wiek",
yaxis = "srednia śmiertelność [%]",
tick_direction = :out,
draw_arrow = true,
legend  = :topleft
)
savefig(rysunki*"histogram_wiek_gory.png")

#udary2018
### Statsmodel dokument
Plots::histogram(ile_szpitali.liczba)

@df ile_szpitali histogram(:liczba,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
color = :lime,
yaxis = "Liczba powiatow",
xaxis = "Liczba oddziałow udarowych w powiecie",
minorticks = true,
tick_direction = :out,
draw_arrow = true,
legend = :none,
xticks = 0:5:10,
)
### model007

model007 = udary[udary.oddzialUdar .!= "trombo", :]

model007[!, :czy030Gory] = (model007.grWiekEks .== "[0,30]") .& model007.czyGory
model007[!, :czy3044Gory] = (model007.grWiekEks .== "(30,44]") .& model007.czyGory
model007[!, :czy7484Gory] = (model007.grWiekEks .== "(74,84]") .& model007.czyGory
model007[!, :czy030Jeziora] = (model007.grWiekEks .== "[0,30]") .& model007.czyJeziora
model007[!, :czy3044Jeziora] = (model007.grWiekEks .== "(30,44]") .& model007.czyJeziora
model007[!, :czy4454Jeziora] = (model007.grWiekEks .== "(44,54]") .& model007.czyJeziora
model007[!, :czy030M] = ((model007.grWiekEks .== "[0,30]") .& (model007.PLEC .== "M"))
model007[!, :czy4454M] = (model007.grWiekEks .== "(44,54]") .& (model007.PLEC .== "M")
model007[!, :czy4454GOP] = (model007.grWiekEks .== "(44,54]") .& model007.czyGOP
model007[!, :czy5464GOP] = (model007.grWiekEks .== "(54,64]") .& model007.czyGOP
model007[!, :czy6474GOP] = (model007.grWiekEks .== "(64,74]") .&  model007.czyGOP
model007[!, :czy7484GOP] = (model007.grWiekEks .== "(74,84]") .&  model007.czyGOP
model007[!, :nowaGrWiek] = ifelse.(in.(model007.grWiekEks, (["[0,30]" "(30,44]" "(44,54]"],)), "[0,54]", model007.grWiekEks)  |> x-> CategoricalArray(x,ordered = true)
poziomy = levels(model007.nowaGrWiek)

poziomy = vcat(poziomy[end], poziomy[1:end-1])
levels!(model007.nowaGrWiek, poziomy)

### model030

model030 = udary[udary.oddzialUdar .!= "trombo", :]

model030[!, :czy4454M] = (model030.grWiekEks .== "(44,54]") .& (model030.PLEC .== "M")
model030[!, :czy5464M] = (model030.grWiekEks .== "(54,64]") .& (model030.PLEC .== "M")
model030[!, :czy6474M] = (model030.grWiekEks .== "(64,74]") .& (model030.PLEC .== "M")
model030[!, :czy7484M] = (model030.grWiekEks .== "(74,748]") .& (model030.PLEC .== "M")
model030[!, :czy74109Gory] = in.(model030.grWiekEks, (["(74,84]" "(84,109]"],)) .& model030.czyGory
model030[!, :czy7484Gory] = (model030.grWiekEks .== "(74,84]") .& model030.czyGory
model030[!, :czy84109Gory] = (model030.grWiekEks .== "(84,109]") .& model030.czyGory
model030[!, :czy5464GOP] = (model030.grWiekEks .== "(54,64]") .& model030.czyGOP
#model030[!, :nowaGrWiek] = ifelse.(in.(model030.grWiekEks, (["[0,30]" "(30,44]"],)), "[0,44]", model030.grWiekEks)
model030[!, :nowaGrWiek] = ifelse.(in.(model030.grWiekEks, (["[0,30]" "(30,44]" "(44,54]"],)), "[0,54]", model030.grWiekEks) |> x-> CategoricalArray(x,ordered = true)
poziomy = levels(model030.nowaGrWiek)
poziomy = vcat(poziomy[end], poziomy[1:end-1])
levels!(model030.nowaGrWiek, poziomy)

#### modele090

model090 = udary[udary.oddzialUdar .!= "trombo", :]


model090[!, :czy4454M] = (model090.grWiekEks .== "(44,54]") .& (model090.PLEC .== "M")
model090[!, :czy5464M] = (model090.grWiekEks .== "(54,64]") .& (model090.PLEC .== "M")
model090[!, :czy6474M] = (model090.grWiekEks .== "(64,74]") .& (model090.PLEC .== "M")
model090[!, :czy7484M] = (model090.grWiekEks .== "(74,84]") .& (model090.PLEC .== "M")
model090[!, :czy74109Gory] = in.(model090.grWiekEks, (["(74,84]" "(84,109]"],)) .& model090.czyGory
model090[!, :czy7484Gory] = (model090.grWiekEks .== "(74,84]") .& model090.czyGory
model090[!, :czy84109Gory] = (model090.grWiekEks .== "(84,109]") .& model090.czyGory
model090[!, :czy7484Jeziora] = (model090.grWiekEks .== "(74,84]") .& model090.czyJeziora
model090[!, :nowaGrWiek] = ifelse.(in.(model090.grWiekEks, (["[0,30]" "(30,44]" "(44,54]"],)), "[0,54]", model090.grWiekEks) |> x-> CategoricalArray(x,ordered = true)
poziomy = levels(model090.nowaGrWiek)

poziomy = vcat(poziomy[end], poziomy[1:end-1])
levels!(model090.nowaGrWiek, poziomy)

#### model365 dane

model365 = udary[udary.oddzialUdar .!= "trombo", :]

model365[!, :czy030Gory] = (model365.grWiekEks .== "[0,30]") .& model365.czyGory
model365[!, :czy3044Gory] = (model365.grWiekEks .== "(30,44]") .& model365.czyGory
model365[!, :czy84109Gory] = (model365.grWiekEks .== "(84,109]") .& model365.czyGory
model365[!, :czy030Jeziora] = (model365.grWiekEks .== "[0,30]") .& model365.czyJeziora
model365[!, :czy4454Jeziora] = (model365.grWiekEks .== "(44,54]") .& model365.czyJeziora
model365[!, :czy7484Jeziora] = (model365.grWiekEks .== "(74,84]") .& model365.czyJeziora
model365[!, :czy5464M] = ((model365.grWiekEks .== "(54,64]") .& (model365.PLEC .== "M"))
model365[!, :czy4454M] = (model365.grWiekEks .== "(44,54]") .& (model365.PLEC .== "M")
model365[!, :czy84109M] = (model365.grWiekEks .== "(84,109]") .& (model365.PLEC .== "M")
model365[!, :czy6474M] = (model365.grWiekEks .== "(64,74]") .& (model365.PLEC .== "M")
model365[!, :czy7484M] = (model365.grWiekEks .== "(74,84]") .& (model365.PLEC .== "M")

model365[!, :nowaGrWiek] = ifelse.(in.(model365.grWiekEks, (["[0,30]" "(30,44]"],)), "[0,44]", model365.grWiekEks) |> x-> CategoricalArray(x,ordered = true)
poziomy = levels(model365.nowaGrWiek)

poziomy = vcat(poziomy[end], poziomy[1:end-1])
levels!(model365.nowaGrWiek, poziomy)

### modele


M007  = glm(@formula(zgon007 ~ nowaGrWiek + czyPowiat + czyPowiat&czyWies + czyPowiat&pow_grodzki +oddzialUdar+czyGOP +lPacj + czy7484Gory+czy4454M + czy4454GOP+czy5464GOP), model007, Binomial(), LogitLink())
M007  = glm(@formula(zgon007 ~ grWiekEks +grWiekEks&PLEC + czyPowiat&czyWies +czyPowiat+lPacj + oddzialUdar  +czyGOP), udary, Binomial(), LogitLink())
M030 = glm(@formula(zgon030 ~ nowaGrWiek+czyPowiat + czyPowiat&czyWies  +oddzialUdar + czyGOP + lPacj + czy4454M +czy6474M +czy74109Gory), model030, Binomial(), LogitLink())
M090  = glm(@formula(zgon090 ~ nowaGrWiek + czyPowiat + czyPowiat&czyWies + oddzialUdar+czyGOP +czy74109Gory + czy4454M + czy5464M  + czy7484M), model090, Binomial(), LogitLink())
M365  = glm(@formula(zgon365 ~ nowaGrWiek + czyPowiat + czyPowiat&czyWies + oddzialUdar+czyGOP+czy84109Gory + czy4454M+czy5464M+czy6474M+czy84109M), model365, Binomial(), LogitLink())
regtable(M007; renderSettings = latexOutput())

regtable(M030; renderSettings = latexOutput())

regtable(M090; renderSettings = latexOutput())

regtable(M365; renderSettings = latexOutput())
StatsBase.mss(x::StatsModels.DataFrameRegressionModel) = 0)
RegressionTables::regtable(M0, M1, M2, M3, M4; below_statistic = :blank, regression_statistics = [:nobs], standardize_coef = false)
TexTables::regtable(M1)


nazwa_model = "M".*["007", "030", "090", "365"]
coefM007 = coef(M007)
coefM030 = coef(M030)
coefM090 = coef(M090)
coefM365 = coef(M365)

stale = DataFrame(wsp = [coefM007[1], coefM030[1], coefM090[1], coefM365[1]], model = nazwa_model)

grupa_wiek = unique(model365.nowaGrWiek)[2:end]

wspolczynniki = vcat([0,0,0, coefM007[2]], reshape(vcat(coefM007[2:5]', coefM030[2:5]', coefM090[2:5]', coefM365[3:6]'), (16,))) # nie podawac drugiego wymiaru

grupy_wiekowe  = DataFrame(wsp = wspolczynniki, grupa = repeat(grupa_wiek, inner = 4), model = repeat(nazwa_model, 5))



grupy_wiek = hcat([0, 0, 0, coefM365[2]], coefM007[2:5], coefM030[2:5], coefM090[2:5], coefM365[3:6])

powiaty = DataFrame(samPowiat = [coefM007[6], coefM030[6], coefM090[6], coefM365[7]], wiesWPowiecie = [coefM007[end-1], coefM030[end], coefM090[end], coefM365[end]], model = nazwa_model)

oddzialy = DataFrame(wsp = vcat(coefM007[7:10], coefM030[7:10], coefM090[7:10], coefM365[8:11]), grupa = repeat([:NieBez, :NieZ, :TakBez, :TakZ], 4), model = repeat(nazwa_model,inner = 4))

plec = DataFrame(wsp = vcat(coefM007[end-4], coefM030[end.-(3:-1:2)], coefM090[end.-(3:-1:2)], 0, coefM090[end-1], coefM365[end.-(4:-1:2)], 0, coefM365[end-1]...), grupa = ["(44,54]", "(44,54]", "(64,74]", "(44,54]", "(54,64]", "(64,74]", "(74,84]", "(44,54]", "(54,64]", "(64,74]", "(74,84]", "(84,109]"], model = vcat(fill.(nazwa_model, (1,2, 4,5))...))

stale |> CSV.write(wyniki*"stale.csv")

grupy_wiekowe |> CSV.write(wyniki*"grupa_wiekowe.csv")

gop = DataFrame(wsp = vcat(coefM007[11], coefM030[11], coefM090[11], coefM365[12]), model = nazwa_model)

gop |> CSV.write(wyniki*"gop.csv")
powiaty |>  CSV.write(wyniki*"powiaty.csv")

gory = DataFrame(wsp = vcat(coefM007[end-5], coefM030[end-1], coefM090[end-4], coefM365[end-5]), model = nazwa_model)
powiaty = CSV.File(wyniki*"powiaty.csv") |> DataFrame

oddzialy |> CSV.write(wyniki*"oddzialy.csv")
gory |> CSV.write(wyniki*"gory.csv")

plec |> CSV.write(wyniki*"plec.csv")
@df grupy_wiekowe plot(:model, :wsp,
group = :grupa,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = [:blue :red :cyan :green :orange],
lw = 1.5,
markersize = 10,
markershape = [:star4 :star5 :star6 :star7 :star8],
seriescolor = [:blue :red :cyan :green :orange],
minorticks = true,
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
yticks = 10,
legend  = :outerright)

savefig(rysunki*"wspolczynniki_grupy_wiekowe.png")


@df stale plot(:model, :wsp,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
lw = 1.5,
markershape = :circ,
markersize = 10,
minorticks = true,
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
yticks = collect(-4.5:.1:-3),
legend  = :none
)

savefig(rysunki*"wspolczynniki_stale.png")


@df powiaty plot(:model, [:samPowiat, :wiesWPowiecie],
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = [:blue :red],
lw = 1.5,
markershape = [:hexagon :diamond],
markersize = 10,
seriescolor = [:blue :red],
label = ["pacjent z tego samego powiatu" "pacjent z gminy wiejskiej z tegoż powiatu"],
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
yticks = -.15:.05:.25,
legend  = :left)

savefig(rysunki*"wspolczynniki_powiaty.png")


@df oddzialy plot(:model, :wsp,
group = :grupa,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = [:blue :red :green :orange],
lw = 1.5,
markershape = [:star4 :star5 :star6 :star8],
markersize = 10,
markeralpha = 0.75,
seriescolor = [:blue :red :green :orange],
label = ["nieleczony bez trombolizy" "nieleczony z trombolizą" "leczony bez trombolizy" "leczony z trombolizą"],
minorticks = true,
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
yticks = -7:1:3,
legend  = :bottomright
)

savefig(rysunki*"wspolczynniki_oddzialy.png")


@df plec plot(:model, :wsp,
group = :grupa,
background_color_legend = :lime,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
linecolor = [:blue :red :cyan :green :orange],
lw = 1.5,
markershape = [:star4 :star5 :star6 :star7 :star8],
markersize = 10,
seriescolor = [:blue :red :cyan :green :orange],
minorticks = true,
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
ytick = -.5:.1:1,
legend  = :bottomleft
)

savefig(rysunki*"wspolczynniki_plec.png")

@df gop plot(:model, :wsp,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
lw = 1.5,
markershape = :circ,
markersize = 10,
minorticks = true,
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
legend  = :none
)

savefig(rysunki*"wspolczynniki_gop.png")

@df gory plot(:model, :wsp,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
linestyle = :dot,
lw = 1.5,
markershape = :circ,
markersize = 10,
minorticks = true,
xaxis = "model",
yaxis = "wartość współczynnika",
tick_direction = :out,
draw_arrow = true,
yticks = -.6:.05:-.1,
legend  = :none
)

savefig(rysunki*"wspolczynniki_gory.png")

wiek_zgon = by(udary[udary.oddzialUdar .!= "trombo", :], :WIEK, (zgony .=> mean)..., sort=true)
nam = wiek_zgon.WIEK
ctg = ["zgon 365-dniowy" "zgon 90-dniowy" "zgon 30-dniowy" "zgon 7-dniowy"]
data = hcat(wiek_zgon.zgon365_mean-wiek_zgon.zgon090_mean,
            wiek_zgon.zgon090_mean-wiek_zgon.zgon030_mean,
            wiek_zgon.zgon030_mean-wiek_zgon.zgon007_mean,
            wiek_zgon.zgon007_mean)
groupedbar(nam, 100data, bar_position = :stack,
foreground_color_legend = :lightgray,
background_color_legend = :lime,
foreground_color_grid = :lightgray,
tick_direction = :out,
gridalpha = .5,
grid_linewidth =  2,
gridstyle = :dot,
gridcolor = :black,
minorticks =true,
           xlabel="wiek [lata]",
           ylabel="średnia śmiertelność [%]",
           legend=:top,
xticks = 0:10:110,
yticks = 0:10:100,
           label=ctg,
           color= ["#00FFFF" "#007FFF" "#0000FF" "	#6C3082"])
           savefig(rysunki*"wiek_smiertelnosc.png")#[


gop = CSV.File(dane*"gop.csv") |> DataFrame
gop[!,:TERYT] = sprintf1.("%04d", gop.TERYT)

regtable(gop; renderSettings = latexOutput())


# Drzewa decyzyjne

wyjasniana = [:zgon007, :zgon030, :zgon090, :zgon365]

objasniajace = [:grWiekEks, :PLEC, :czyPowiat, :czyWies, :oddzialUdar, :lPacj, :czyGOP, :czyGory]

macierz = Matrix(udary[:, objasniajace])

for zgon in wyjasniana
    wektor = udary[:, :zgon007]
    model = build_tree(macierz, wektor)
    model = DecisionTreeClassifier(max_depth=10)
# apply learned model
    apply_tree(model)
# run 3-fold cross validation, returns array of coefficients of determination (R^2)
    n_folds = 10
    r2 = nfoldCV_tree(zgon, macierz, n_folds)
end
