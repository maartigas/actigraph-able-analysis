%% CONFIGURACIO
% Executar amb Run des de MATLAB. Actualitza la carpeta RESULTATS.
projectDir = string(fileparts(mfilename("fullpath")));
addpath(fullfile(projectDir, "FUNCTIONS"));

% Adapteu aquesta ruta a la carpeta local que conté ActiGraph i ABLE_Daily_Dades.
documentsDir = fullfile(string(getenv("USERPROFILE")),"OneDrive","Documents");
actiDir = fullfile(documentsDir, "ActiGraph", "ActiLife", "Downloads");
ableDir = fullfile(documentsDir, "ABLE_Daily_Dades");
zone = "Europe/Madrid";

s = struct([]);
s(1).ID = "Investigadora";
s(1).Day = datetime(2026,10,5,"TimeZone",zone);
s(1).Acti = fullfile(actiDir,"Example_Data_Actigraph_Exo_Mine","01_32Hz_16g_PPGRed_1H10min");
s(1).HR = "HR_Mine";
s(1).Able = fullfile(ableDir,"Dades_Meves_Exo");
s(1).Log = "2026-10-05_152428_logs.log";
s(1).ZipMember = "";
s(1).Export = "20261005T143107";
s(1).Register = "Registre_Prova_Meva.xlsx";

s(2).ID = "Pacient";
s(2).Day = datetime(2026,10,14,"TimeZone",zone);
s(2).Acti = fullfile(actiDir,"Example_Data_Actigraph_Exo_Patient","01_32Hz_16g_PPGRed_1H38min");
s(2).HR = "HR_Patient";
s(2).Able = fullfile(ableDir,"Dades_Pacient_Exo");
s(2).Log = fullfile("20261015_105210","ExoLogs_C47_128-160_2026-10-15_104742.zip");
s(2).ZipMember = "2026-10-14_145743_logs.log";
s(2).Export = "20261014T145747";
s(2).Register = "Registre_Prova_Pacient.xlsx";

% Afegiu parelles confirmades del mateix esdeveniment a Config.Anchors.
% Columnes: AbleTime, ActiTime (datetime amb zona), UseForFit (logical).
% Un ancoratge ajusta offset. Dos o mes poden ajustar deriva si es demana.
Config.Anchors = {table; table};
Config.FitDrift = false;
Config.ExportBinary = true;
Config.MakePlots = true;
outDir = fullfile(projectDir,"RESULTATS");
if ~isfolder(outDir), mkdir(outDir); end
plotData = struct([]);

%% LECTURA, SINCRONITZACIO I RESUMS
for k = 1:numel(s)
    session = s(k);
    fprintf("\n--- %s ---\n", session.ID);
    folder = fullfile(outDir,session.ID);
    if ~isfolder(folder), mkdir(folder); end

    A = readActiSession(session);
    E = readAbleSession(session,Config.ExportBinary);
    T = readTrialRegister(session,A.Markers,E.States);
    [E, Sync, Anchors] = alignSession(E,A,Config.Anchors{k},Config.FitDrift);
    restStart = T.Start(T.PhaseNo==1 & T.PhaseType=="Repòs / recuperació");
    assert(isscalar(restStart),"Cal l'inici del repòs de la fase 01 (%s).",session.ID);
    stop = E.StopAligned;
    if session.ID=="Pacient"
        finalRecovery = T.Stop(T.Usable & startsWith(T.Activity,"Recuperació final"));
        stop = min([stop;finalRecovery]);
    end
    [A,T] = trimActiSession(A,T,restStart,stop);
    [Trials, Minutes, Bouts, Session, HRV, Relations] = summarizeSession(session,A,E,T);
    [Gait, GaitPhasePct] = summarizeStraightGait(session,E,Trials,Bouts);

    %% EXPORTACIO
    writetable(Sync,fullfile(folder,"sincronitzacio.csv"));
    if ~isempty(Anchors), writetable(Anchors,fullfile(folder,"ancoratges.csv")); end
    writetable(Session,fullfile(folder,"resum_sessio.csv"));
    writetable(Trials,fullfile(folder,"resum_activitats.csv"));
    phaseColumns = ["PhaseNo","FigurePhaseNo","Activity","PhaseType","Start","Stop","TimeSource", ...
        "WorkbookRow","RegisterStart","RegisterStop","FigureStart","FigureStop", ...
        "ABLECoverage_s","ABLESteps","ABLEDistance_m_est","DistancePerWindow_mps_est", ...
        "Acti_VM_mean_CPM","ActiEpochN","HR_mean_bpm","HR_N"];
    writetable(sortrows(Trials(:,phaseColumns),"PhaseNo"),fullfile(folder,"fases_i_resultats.csv"));
    writetable(Minutes,fullfile(folder,"finestres_60s.csv"));
    writetable(Bouts,fullfile(folder,"trams_marxa.csv"));
    writetable(Gait,fullfile(folder,"marxa_per_tram.csv"));
    writetable(Relations,fullfile(folder,"relacions_exploratories.csv"));
    writetable(E.Steps,fullfile(folder,"passes_able.csv"));
    writetable(E.States,fullfile(folder,"estats_able_care.csv"));
    writetable(E.Parameters,fullfile(folder,"canvis_parametres_able.csv"));
    writetable(E.ClockUpdates,fullfile(folder,"actualitzacions_rellotge_able.csv"));
    writetable(A.Markers,fullfile(folder,"marques_actigraph.csv"));
    writetable(HRV,fullfile(folder,"hrv_5min.csv"));
    writetable(summarizeTemperature(A,Trials),fullfile(folder,"temperatura_per_estat.csv"));
    if Config.ExportBinary
        writetable(E.BinaryInfo,fullfile(folder,"inventari_telemetria.csv"));
        writetable(E.BinaryFields,fullfile(folder,"camps_telemetria.csv"));
    end
    save(fullfile(folder,"dades_i_resultats.mat"),"A","E","T","Trials","Minutes", ...
        "Bouts","Session","Sync","Anchors","HRV","Relations", ...
        "Gait","GaitPhasePct","-v7.3");
    if Config.MakePlots
        plotData(k).Folder = folder;
        plotData(k).ActiGraph = A;
        plotData(k).Minutes = Minutes;
        plotData(k).Trials = Trials;
        plotData(k).Gait = Gait;
        plotData(k).GaitPhasePct = GaitPhasePct;
    end

    disp(Session(:,["Session","ABLEStepsTotal","ABLEDistanceTotal_m_est","ABLEAverageSpeed_mps_est", ...
        "HR_mean_bpm","RMSSD_mean_ms","Acti_VM_mean_CPM"]));
    if ~isempty(Gait)
        fprintf("Marxa recta i contínua | %s\n",session.ID);
        gaitColumns = ["Temps_s","Passes","Distancia_m_est","Velocitat_m_s_est","Cadencia_passes_min", ...
            "Longitud_passa_m_est","Suport_s","Balanceig_s","Doble_suport_s"];
        gaitLabels = ["Temps (s)";"Passes";"Distància est. (m)"; ...
            "Velocitat est. (m/s)";"Cadència (passes/min)";"Longitud de passa est. (m)"; ...
            "Suport total (s)";"Balanceig (s)";"Doble suport total (s)"];
        GaitDisplay = array2table(Gait{:,gaitColumns}.', ...
            'VariableNames',cellstr(Gait.Tram.'),'RowNames',cellstr(gaitLabels));
        disp(GaitDisplay);
    end
end

fprintf("\nResultats a %s\n", outDir);

%% FIGURES
for k = 1:numel(plotData)
    p = plotData(k);
    plotSession(p.Folder,s(k),p.ActiGraph,p.Minutes,p.Trials,p.Gait,p.GaitPhasePct);
end
