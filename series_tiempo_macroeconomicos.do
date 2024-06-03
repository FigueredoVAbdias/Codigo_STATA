**************************************************************************************************************

*   Series de tiempo BALANZA COMERCIAL BOLIVIA-EEUU
*
**************************************************************************************************************

set fredkey dcd2a47e8017386f6f5fcd4259eb0390 
import fred IMP3350, clear
summarize
rename IMP3350 exports_USA
describe
browse
generate montly=mofd(daten)
format montly  %tm
*  Especificar estructura de la serie de tiempo
tsset montly
list daten montly exports_USA if  tin(1992m1,1992m6)
list montly exports_USA L.exports_USA  L2.exports_USA F.exports_USA D.exports_USA if tin(1992m1,1992m6), noobs
tsline exports_USA, title("Exportaciones mensuales de mercancías a EEUU") subtitle("1992m1-2024m2")  ytitle("Millones de $us")    xtitle("periodo") note(Fuente: "FRED, U.S. Census Bureau; U.S. Bureau of Economic Analysis")
tsline    D.exports_USA, title("Exportaciones mensuales de mercancías a EEUU (primera diferencia)") subtitle("1992m1-2024m2")  ytitle("    ")    xtitle("    ") note(Fuente: "U.S. Census Bureau; U.S. Bureau of Economic Analysis")

****************************************************************************************************************

*Series de tiempo ACCESO A INTERNET BOLIVIA

****************************************************************************************************************
import fred ITNETUSERP2BOL, daterange(1995-01-01 2021-01-01) clear
sum
ren ITNETUSERP2BOL usuarios
generate year=yofd(daten)
label var year "año"

tsset year,yearly

list if tin(1995,2000)

*************************************************************
*Box Jenkins*
*************************************************************

**************************************************************
*1. Identificación
***************************************************************
* grafico plot para identificar si es una serie estacionaria o no
tsline usuarios, name(level,replace) title("% de internautas") subtitle("1995-2021")  ytitle("porcentaje") xtitle("periodo") note(Fuente: "FRED, World Bank")
	
* grafico plot para identificar si es una serie estacionaria o no en sus primeras diferencias
tsline D.usuarios, name(difference,replace) title("% de internautas (primera diferencia)") subtitle("1995-2021")  ytitle("porcentaje")title("periodo") note(Fuente: "FRED, World Bank")

*combinacion de los dos graficos	
graph combine level difference,rows(2) 

*correlogramas en la 1ra. diferencia para usuarios: una serie no estacionaria
*tiene caida suave, de ello podemos identificar procesos de media movil MA
ac D.usuarios,lags(10) ytitle(" ") name(ac_internautas,replace)title("Función de Autocorrelación de internautas") ylabels(#4,angle(0))

*autocorrelacion parcial en la 1ra diferencia de usuarios: una serie no 
*estacionario tiene caida abrupta de ello podemos identificar procesos de autoregresivos AR
pac D.usuarios,lags(10) ytitle(" ") name(pac_internautas,replace)title("Función de Autocorrelación Parcial de internautas") ylabels(#4,angle(0))

*raiz unitaria de D.fuller para identificar el mejor proceso de MA y RA y verificar si es series no estacionaria
* si el p es > no se rechaza la HO de raiz unitaria la serie es no estacionaria al 95% de confianza
dfuller usuarios

*raiz unitaria para la 1ra diferencia
dfuller D.usuarios

*combinacion de autocorrelograma de MA y RA	
graph combine ac_internautas pac_internautas,rows(2)



**************************************************************
*2. Estimación
**************************************************************
*se debe revisar si los estimadores son significativos 
*<0.05 es significativo y >0.05 no es significativo
*luego elegimos el ARIMA con los estimadores mas significativos para validarlo
arima D.usuarios, arima(1,0,1) nolog vsquish
arima D.usuarios, arima(1,0,0) nolog vsquish
arima D.usuarios, arima(2,0,0) nolog vsquish
*tarea el resto


**************************************************************
*3. Validación
************************************************************** 
*el arima elegido debe tener residuos con raiz unitaria
****************
*test de portmanteau
*H0: el proceso es ruido blanco

*ARIMA(1,1) 
quietly arima D.usuarios, arima(1,0,1)
*calculo de residuos
predict resid11, resid
*test de portmanteau: >0.05 no se rechaza la Ho los residuos son ruido blanco 
wntestq resid11
*grafico de test
wntestb resid11
*estadisticos del ARIMA: El mejor AIC es el mas pequeño
estat ic

*la media del error debe ser cero
summarize resid11
scalar media_error11= r(mean)
tsline resid11, yline(`r(mean)')

*ARIMA(1,0) 
quietly arima D.usuarios, arima(1,0,0)
predict resid12, resid
wntestq resid12
wntestb resid12

estat ic

*ARIMA(2,0) tarea para la casa


**************************************************************
*Predicción 
**************************************************************
*pronosticar 5 años 
tsappend, add(5)
*realizar el arima en niveles de lo variable y no sus diferencias
arima usuarios, arima(1,1,0) //Modelo seleccionado
*crea una nueva variable con los pronosticos
predict usuariosf, y dynamic(y(2022))
*grafico con la variable orignal y la variable pronosticada
tsline usuariosf usuarios


***************************************************************

* Instalar acceso a datos el Banco mundial en Stata

****************************************************************************************************************

*Series de tiempo PIB PERCAPITA BOLIVIA

****************************************************************************************************************
ssc install wbopendata // este comando instala el modulo en stata
*db wbopendata  // Para ver el menu
wbopendata, language(es - Spanish) country(BOL;) topics() indicator(NY.GDP.PCAP.KD - GDP per capita(constant 2010 US$)) clear long
sum
ren ny_gdp_pcap_kd pibpc
tsset year,yearly
list year pib if tin(1960,1970) 
tsline pib, name(level,replace) title("PIB percápita en $us constantes de 2010") subtitle("1960-2022")  ytitle("$us") xtitle("periodo") note(Fuente: "World Bank")
tsline D.pib, name(difference,replace) title("PIB percápita en $us constantes de 2010 (1ra diferencia") subtitle("1960-2022")  ytitle("$us") xtitle("periodo") note(Fuente: "World Bank")
graph combine level difference,rows(2) 

