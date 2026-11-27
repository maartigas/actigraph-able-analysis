# ActiGraph LEAP i ABLE Daily

MATLAB workflow for separate analysis of researcher and patient recordings.
The reported figures show ABLE steps and estimated speed, heart rate, wrist
activity counts, skin temperature, and mean gait-phase proportions by leg.

**Quick start:** use MATLAB R2024b, configure the local input paths in `main.m`,
and run the script. All required project helper functions are included in
`FUNCTIONS`; a separate `Codi_Actigraph_Only` checkout is not required.
The participant input files are not included in the code distribution.
Raw red/infrared PPG loading is commented out and is not required to run the
current analysis. Generated results remain local in `RESULTATS`.

Anàlisi per separat de la investigadora (05/10/2026) i del pacient (14/10/2026).

El minut **0** dels gràfics correspon a l'inici del repòs de la fase **01**. L'anàlisi de la investigadora va de les **15:31:42** a les **16:32:31,364**, quan acaba el log ABLE. La del pacient va de les **15:08:00** a les **16:24:00** (minut **76**), al final del tram gris de recuperació. Els resums i els gràfics fan servir aquests intervals.

Les èpoques de VM i freqüència cardíaca que travessen un límit queden excloses. Als extrems de la sessió de la investigadora, el recompte ABLE, la velocitat estimada i la temperatura es calculen amb les mostres de les finestres parcials de **18 s** i **31,364 s**. L'RMSSD conserva les finestres completes de la seva durada.

## Executar

Obre **main.m** amb MATLAB R2024b i prem **Run**. Totes les funcions auxiliars necessàries són a **FUNCTIONS**. La ruta **documentsDir** parteix de la carpeta OneDrive/Documents de l'usuari de Windows; adapta-la a la ubicació de les dades del teu ordinador. Les sessions i els llindars de referència també es configuren a **main.m**.

**RESULTATS** conté **Investigadora** i **Pacient**. El programa actualitza els fitxers d'aquestes dues carpetes. Les figures anteriors de comparació entre persones queden a **HISTORIAL_RESULTATS**.

Es generen **dues figures per sessió**, sense títols i amb tots els textos en anglès. El resum té cinc panells i s'ha ampliat en alçada per mantenir-ne la llegibilitat. La lectura del PPG cru està comentada; l'execució normal no carrega aquestes mostres ni genera figures PPG. Els fitxers originals i les figures PPG ja existents es conserven localment.

| Sortida per sessió | Contingut |
| --- | --- |
| **00_resum_sessio_5_panells.png** | Passes ABLE per finestra, velocitat estimada ABLE, freqüència cardíaca, **Wrist activity (counts/min)** i **Skin temperature (°C)**. Els cinc panells comparteixen temps i franges de fases. La velocitat és la distància estimada dividida per la durada de la finestra, pauses incloses. |
| **04_fases_cicle_marxa_mitjanes.png** | Dues barres en un sol eix, amb la mitjana del cicle esquerre en taronja i la del dret en verd turquesa. |
| **marxa_per_tram.csv** | Mètriques ABLE de marxa recta o contínua i 2MWT per tram, amb una fila de mitjana. Inclou els límits del registre, el número de fase del gràfic i el nombre de cicles per cama. |
| **temperatura_per_estat.csv** | Temperatura mitjana, nombre de mostres i diferència respecte al repòs inicial, per a l'aixecament i la marxa. |
| **PPG_RAW/** | Figures crues PNG i MATLAB `.fig` ja desades, conservades per a una revisió futura. |
| **fases_i_resultats.csv** | Llegenda detallada de les fases, amb hora d'inici i fi, font del límit temporal, cobertura ABLE, passes, distància, velocitat, VM, freqüència cardíaca i nombre de mesures. Les activitats sense un interval utilitzable conserven la seva fila. |
| **finestres_60s.csv**, **resum_sessio.csv**, **resum_activitats.csv** i **passes_able.csv** | Valors de detall per minut, totals, mètriques per activitat i registre de cada passa. **Temperature_mean_C** i **Temperature_N** indiquen la temperatura mitjana i el nombre de mostres de cada interval. |

Les franges verticals de color indiquen la durada de les fases. El color identifica el tipus de tasca i el número distingeix les repeticions. Les zones blanques indiquen trams sense fase anotada, com ara desplaçaments entre proves. Al gràfic del pacient, la franja 09 es mostra en blau sota la llegenda «Marxa recta / contínua» i correspon al 2MWT, identificat amb el número 10 a **PhaseNo** de **fases_i_resultats.csv**. Els intervals que sobrepassen la gravació es retallen visualment al final del registre. Per als resums per fase es fan servir només les èpoques completes de VM que cauen dins l'interval. En una fase curta, **ActiEpochN = 0** pot coexistir amb counts visibles al gràfic de la sessió, perquè els counts pertanyen a un minut que travessa el límit de la fase. Les hores i la font es mantenen a la taula.

Les fases parteixen del full **Actigraph_Proves** de cada Excel. **RegisterStart** i **RegisterStop** són les hores de l'Excel, i **Start** i **Stop** són els límits dels càlculs per fase. **FigureStart** i **FigureStop** indiquen l'interval que es dibuixa. **FigurePhaseNo** indica el número de la franja als gràfics. **TimeSource** indica el criteri i **WorkbookRow** permet trobar la fila de l'Excel. Un zero al panell de passes indica una finestra coberta pel log ABLE sense increments del comptador de passes. Les franges poden començar dins d'una finestra de 60 s.

**Sit-to-stand** identifica l'aixecament i **stand-to-sit** el retorn a seure. A la investigadora, la franja del gir de 90° cobreix el minut 15:42–15:43 per situar-lo sobre el tram de menys passes. Les mètriques del gir es calculen amb les marques de 15:42:10–15:42:27. En la investigadora, es fan servir parelles de pulsacions llargues quan la durada i el minut anotats hi concorden. Això inclou el repòs inicial, l'aixecament, la marxa exterior, el gir de 90° i la baixada amb ascensor. Al pacient, el final de l'aixecament s'estén fins a l'estat dempeus registrat a les 15:11:06,833 al log d'ABLE Care. A la investigadora, l'inici de la recuperació final es pren del final de la segona simulació de marxa, a les 16:29:21, per separar els dos intervals. Al pacient, el començament de la marxa addicional es pren del final del 2MWT, a les 15:58:33, seguint el registre. Les simulacions de 142 s i 174 s i el 2MWT del pacient de 120 s es resumeixen en els seus intervals respectius.

Als gràfics del pacient, els dos blocs rectes inicials comparteixen la franja 03, de **15:17 a 15:22**. La franja 09 agrupa la prova de 120 s i la continuació immediata, amb límits visuals de **15:54 a 15:59**. La franja 13 inclou el pic fins a **16:07**. **FigurePhaseNo** conté la numeració visible, de 01 a 16. La taula específica **marxa_per_tram.csv** utilitza aquestes tres franges completes per calcular els trams del pacient.

## Com es calculen els counts

S'utilitza el CSV **60secDataTable.csv** exportat amb ActiLife **v7.3.3**, filtre **Normal** i èpoques de **60 s**. En l'algoritme publicat d'ActiLife, el senyal de cada eix es filtra en freqüència, s'escala, es rectifica i es quantifica abans de sumar els valors dins de cada època. ActiLife combina els tres counts de cada època amb la magnitud vectorial **VM = √(Axis1² + Axis2² + Axis3²)**. Com que cada època dura un minut, la unitat de la figura és counts/min. MATLAB llegeix la VM exportada i comprova la fórmula amb els tres eixos, amb tolerància d'arrodoniment. [Algoritme d'ActiLife, Neishabouri et al.](https://www.nature.com/articles/s41598-022-16003-x) · [Manual d'ActiLife, apèndix B](https://dl.theactigraph.com/SFT12DOC13%20-%20ActiLife%206%20Users%20Manual%20%28Rev%20A%29.pdf)

### Rangs orientatius de VM

El quart panell dels dos resums de sessió utilitza els llindars de Veerubhotla et al. (2020), amb l'eix **Wrist activity (counts/min)**. El senyal continua sent la magnitud vectorial exportada per ActiLife. Les dues línies horitzontals són a **2.057** i **11.551 counts/min**. Al centre de cada franja s'indica **Sedentary**, **Light** o **Moderate-to-vigorous**. L'estudi agrupa la intensitat moderada i vigorosa.

| Sedentària | Lleugera | Moderada–vigorosa |
| ---: | ---: | ---: |
| <2.057 | ≥2.057 i <11.551 | ≥11.551 |

Els llindars es van obtenir en usuaris de cadira de rodes manual amb lesió medul·lar, amb l'ActiGraph al canell dominant i mesures de consum d'oxigen com a referència. S'apliquen a les dues sessions com a referència exploratòria. La seva aplicació a la marxa amb ABLE i a una investigadora sense lesió medul·lar queda per validar. La postura i la tasca aporten context a la categoria sedentària suggerida pels counts. [Veerubhotla et al. (2020)](https://pubmed.ncbi.nlm.nih.gov/32502566/) · [Consens sobre conducta sedentària](https://pmc.ncbi.nlm.nih.gov/articles/PMC5466781/)

## Temperatura cutània

El cinquè panell mostra **Skin temperature (°C)**, la mitjana aritmètica de les mostres finites durant el temps d'ús validat de cada interval d'un minut. Es dibuixa al punt central de l'interval, igual que al gràfic anterior de temperatura. Les finestres parcials dels extrems utilitzen només les mostres que els corresponen. Els intervals sense mostra vàlida queden buits. El codi no aplica interpolació ni un nou filtre a la temperatura.

**temperatura_per_estat.csv** conserva la comparació dins de cada sessió. El repòs basal correspon a la fase 01 del registre. L'activació correspon a l'aixecament i la marxa inclou les fases anotades de marxa recta, 2MWT, rampes de pujada i baixada, eslàlom i marxa amb acompanyament. La mitjana de cada estat es calcula amb totes les mostres finites i validades dins dels seus límits analítics. La diferència es calcula respecte al repòs inicial de la mateixa sessió. Quan manca temperatura basal o de l'estat, la diferència queda buida.

## PPG cru desactivat

Les dues línies que llegien **ppg50hz.csv** i creaven **A.PPGRaw** estan comentades a **FUNCTIONS/readActiSession.m**. No s'executa cap càlcul de saturació d'oxigen. Els nous fitxers **dades_i_resultats.mat** no inclouen **A.PPGRaw**. Els CSV originals i les figures de **PPG_RAW** ja desades es mantenen per a una possible revisió futura.

La funció auxiliar **plotRawPPG** es conserva fora del flux actiu, sense cap crida des de **main.m**. Per tornar a fer-la servir caldria reactivar explícitament la lectura comentada. Aquesta funció només representa les mostres originals i no calcula saturació.

## Alineació i cobertura

Les dues fonts s'alineen directament per timestamp local (**Europe/Madrid**), amb **0 s** de correcció en les sessions actuals. L'error absolut entre els rellotges no s'ha quantificat de manera independent. Els **60 s** corresponen a la durada de les èpoques ActiLife i dels resums temporals, no a un marge d'error de sincronització. Moltes fases del registre manual també tenen les hores anotades al minut. **sincronitzacio.csv** documenta el mètode i les resolucions dels timestamps. Si es disposa d'esdeveniments comuns confirmats, es poden introduir amb **Config.Anchors** per ajustar el rellotge.

Les passes i la distància es recuperen del log intern de l'ABLE. La distància acumulada coincideix amb la suma de les longituds de passa en unitats del log. El patró és coherent amb centímetres i la conversió a metres és provisional, marcada amb **_est**. Es calcula la velocitat de finestra només quan el log ABLE cobreix tota la finestra. A la taula per fases, **ABLECoverage_s** indica el temps cobert i les sumes en un interval parcial representen únicament el tram observat. El binari de l'ABLE es conserva com a telemetria auxiliar amb el seu rellotge intern. [Informe de sessió d'ABLE](https://www.ablehumanmotion.com/en/able-exoskeleton-neurorehabilitation-features/)

La taula i les fases mitjanes de marxa del pacient utilitzen les tres franges de marxa contínua del resum visual, amb els límits **FigureStart** i **FigureStop**. **Marxa contínua 1** és la fase 03, de 15:17 a 15:22. **Marxa contínua 2** és la fase 09, de 15:54 a 15:59. **Marxa contínua 3** és la fase 13, de 16:03 a 16:07. Els càlculs de cada tram inclouen totes les passes i els cicles complets dins d'aquests límits. **Fase_grafic** relaciona cada tram amb els resums. Per a la investigadora es conserven els límits analítics **Start** i **Stop** del registre. Les dues simulacions s'identifiquen com a **2 Minute Walk Test 1** i **2 Minute Walk Test 2**, i duren 142 i 174 s segons les marques. La velocitat i la cadència divideixen, respectivament, la distància i les passes pel temps de tot el tram, amb les pauses incloses. La longitud de passa és la distància estimada dividida per les passes comptades. La fila **Mitjana** dona el mateix pes als valors disponibles de cada tram.

Les fases es reconstrueixen amb els temps del firmware i tres registres consecutius alterns dins del tram, E-D-E o D-E-D. S'aplica la mateixa separació que a **trams_marxa.csv** quan passen més de 5 s entre registres. El codi comprova que el doble suport inicial, el suport simple i el doble suport final sumin el suport total del firmware. En afegir el balanceig s'ha d'obtenir la durada del cicle. La taula mostra les mitjanes en segons dels cicles vàlids de les dues cames. El doble suport total ja forma part del suport total. La figura mostra les fases mitjanes de cada cama, donant el mateix pes als trams amb cicles vàlids. El format segueix el panell D de l'article de referència. [Figura 2 de l'estudi ABLE i KAFO](https://www.nature.com/articles/s41598-022-23556-4/figures/2)

La taula de MATLAB i **resum_sessio.csv** mostren la freqüència cardíaca mitjana en bpm, l'RMSSD mitjà en ms i la VM mitjana en counts/min. S'inclouen les mostres finites de freqüència cardíaca durant el temps d'ús i els minuts complets amb VM disponible. L'RMSSD mitjà de sessió és la mitjana aritmètica dels valors numèrics del fitxer **HeartRateVar.csv**, amb finestres solapades de cinc minuts. El fitxer **hrv_5min.csv** inclou el camp **hrv_reliability** per revisar la qualitat de cada finestra. Són sortides auxiliars del codi; la seva generació no implica que es reportin als resultats del treball.

La freqüència cardíaca prové dels CSV de l'aplicació separada d'ActiGraph distribuïda com **hr_1.2.0**. MATLAB importa aquests resultats i valida les hores locals amb el camp UTC. Els intervals sense mostra vàlida queden buits al gràfic. Els resums auxiliars de respiració, temperatura, HRV i telemetria es conserven als fitxers detallats per sessió.

## Distribució del codi a GitHub

La distribució de codi conté només **main.m**, **README.md**, **.gitignore** i els fitxers **.m** de **FUNCTIONS**. El paquet **CODI_PER_GITHUB.zip** es prepara amb aquesta llista explícita de fitxers. Descomprimeix-lo localment i puja'n el contingut perquè el codi es pugui consultar directament al repositori.

Les carpetes **RESULTATS** i **HISTORIAL_RESULTATS**, les dades dels participants i els executables del fabricant no formen part d'aquesta distribució. **.gitignore** exclou les sortides generades i els principals formats de dades quan es fa servir Git. En una pujada manual pel navegador, selecciona només el contingut del paquet de codi preparat.

Les dades locals necessàries per executar l'anàlisi són els exports ActiLife d'activitat de 60 s, temperatura, event markers i wear; els CSV fisiològics de les carpetes HR; els registres del controlador ABLE, l'export ABLE Care i el full de registre d'activitats. La configuració actual correspon a les dues sessions de l'estudi i cal adaptar les rutes i les anotacions si s'aplica a altres enregistraments.

