function T = readTrialRegister(s,markers,ableStates)
% Nomes es llegeix la cronologia. Es conserven files sense hores.
if s.ID=="Pacient"
    firstRow = 15;
    lastRow = 36;
    cols = [5 6];
else
    firstRow = 17;
    lastRow = 34;
    cols = [4 5];
end
U = readcell(fullfile(s.Able,s.Register),"Sheet","Actigraph_Proves", ...
    "Range",sprintf("A%d:I%d",firstRow,lastRow));
n = size(U,1);
start = NaT(n,1,"TimeZone",s.Day.TimeZone);
stop = start;
block = strings(n,1);
activity = strings(n,1);
status = strings(n,1);
for i = 1:n
    block(i) = string(U{i,2});
    activity(i) = string(U{i,3});
    if s.ID=="Pacient", status(i) = string(U{i,4}); end
    start(i) = registerTime(U{i,cols(1)},s.Day);
    stop(i) = registerTime(U{i,cols(2)},s.Day);
end
WorkbookRow = (firstRow:lastRow)';
T = table(WorkbookRow,block,activity,status,start,stop, ...
    'VariableNames',["WorkbookRow","Block","Activity","RegisterStatus","RegisterStart","RegisterStop"]);
T.Start = start;
T.Stop = stop;
T.TimeSource = repmat("Excel_minut_aproximat",n,1);

if s.ID=="Pacient"
    % El log confirma que l'aixecament acaba just després del minut anotat.
    rise = WorkbookRow==16;
    t = ableStates.TimeABLECare;
    nearRise = t>=T.Start(rise) & t<T.Stop(rise)+minutes(1);
    rising = find(nearRise & ableStates.State=="Standing up",1);
    if ~isempty(rising)
        upright = find(nearRise & t>=t(rising) & ableStates.State=="Standing upright",1);
        if ~isempty(upright) && t(upright)>T.Stop(rise)
            T.Stop(rise) = t(upright);
            T.TimeSource(rise) = "Inici_Excel_fi_dempeus_ABLECare";
        end
    end
    % La prova i la continuació immediata formen una sola fase de marxa contínua.
    walk = WorkbookRow==25;
    continuation = WorkbookRow==26;
    T.Activity(walk) = "Marxa contínua — prova de 120 s i continuació";
    T.Stop(walk) = T.Stop(continuation);
    T.RegisterStop(walk) = T.RegisterStop(continuation);
    T.TimeSource(walk) = "Excel_files_25_i_26_inici_al_segon_fi_aproximada";
    T(continuation,:) = [];
    WorkbookRow = T.WorkbookRow;
else
    % Parelles de long press coherents amb el minut i la durada del full.
    % Son inferencies de tasca a ActiGraph, no ancoratges entre dispositius.
    proposed = [
        17 "15:31:42" "15:34:20"
        18 "15:34:20" "15:34:55"
        19 "15:37:39" "15:42:01"
        20 "15:42:10" "15:42:27"
        21 "15:54:40" "15:55:22"
        22 "15:55:35" "15:56:32"
        23 "15:56:41" "15:57:28"
        24 "16:09:35" "16:11:31"
        25 "16:15:38" "16:16:59"
        26 "15:47:00" "15:50:34"
        28 "16:16:59" "16:17:23"
        29 "16:17:23" "16:20:24"
        30 "16:23:08" "16:25:30"
        31 "16:25:30" "16:26:27"
        32 "16:26:27" "16:29:21"];
    longPress = markers.Timestamp(markers.Long_Press_Count>0);
    for j = 1:size(proposed,1)
        i = WorkbookRow==str2double(proposed(j,1));
        a = registerTime(proposed(j,2),s.Day);
        b = registerTime(proposed(j,3),s.Day);
        assert(all(ismember([a,b],longPress)),"Falta la marca llarga proposada: %s / %s (%s).",string(a),string(b),proposed(j,1));
        T.Start(i) = a;
        T.Stop(i) = b;
        T.TimeSource(i) = "Long_press_inferit_per_minut_i_durada";
    end
    % La recuperació final és posterior a la segona simulació.
    T.Start(WorkbookRow==33) = T.Stop(WorkbookRow==32);
    T.TimeSource(WorkbookRow==33) = "Inici_heretat_R2_fi_aproximada";
end

missing = isnat(T.Start) | isnat(T.Stop);
T.TimeSource(missing) = "Sense_interval";
T.TimeSource(~missing & T.Stop<=T.Start) = "Mateix_minut_sense_limits_distints";
T.Usable = ~missing & T.Stop>T.Start;
T.Start.Format = "yyyy-MM-dd HH:mm:ss.SSS";
T.Stop.Format = T.Start.Format;
T.FigureStart = T.Start;
T.FigureStop = T.Stop;
if s.ID=="Investigadora"
    % Mostra la corba de 90° sobre tot el minut de la baixada de passes.
    turn = WorkbookRow==20;
    T.FigureStart(turn) = dateshift(T.Start(turn),"start","minute");
    T.FigureStop(turn) = T.FigureStart(turn)+minutes(1);
    straight = WorkbookRow==19;
    T.FigureStop(straight) = min(T.FigureStop(straight),T.FigureStart(turn));
elseif s.ID=="Pacient"
    % Fase 03 i 04 en una sola franja, amb el tram intermedi.
    firstWalk = WorkbookRow==18;
    secondWalk = WorkbookRow==19;
    T.FigureStop(firstWalk) = T.Stop(secondWalk);
    hidden = NaT(1,1,"TimeZone",s.Day.TimeZone);
    T.FigureStart(secondWalk) = hidden;
    T.FigureStop(secondWalk) = hidden;
    % Límits visuals segons els esglaons de passes del gràfic.
    T.FigureStart(WorkbookRow==25) = registerTime("15:54:00",s.Day);
    T.FigureStop(WorkbookRow==30) = registerTime("16:07:00",s.Day);
end

% Numeració cronològica. Els intervals sense dos límits queden sense número.
n = height(T);
usable = find(T.Usable);
[~,order] = sort(T.Start(usable));
T.PhaseNo = NaN(n,1);
T.PhaseNo(usable(order)) = (1:numel(usable))';
T.FigurePhaseNo = T.PhaseNo;
if s.ID=="Pacient"
    chronological = usable(order);
    visible = chronological(~isnat(T.FigureStart(chronological)) & ~isnat(T.FigureStop(chronological)));
    T.FigurePhaseNo(:) = NaN;
    T.FigurePhaseNo(visible) = (1:numel(visible))';
    T.FigurePhaseNo(secondWalk) = T.FigurePhaseNo(firstWalk);
end
name = lower(T.Activity);
T.PhaseType = repmat("Altres",n,1);
T.PhaseType(contains(name,["repòs","recuperació"])) = "Repòs / recuperació";
T.PhaseType(contains(name,"sit-to-stand")) = "Sit-to-stand";
T.PhaseType(contains(name,"stand-to-sit")) = "Stand-to-sit";
T.PhaseType(contains(name,["pausa","ajustos"])) = "Pausa / ajustos";
T.PhaseType(contains(name,"marxa")) = "Marxa recta";
T.PhaseType(contains(name,["gir","curva"])) = "Gir";
T.PhaseType(contains(name,["gir","curva"]) & contains(name,"90")) = "Gir de 90°";
T.PhaseType(contains(name,"rampa") & contains(name,"gir")) = "Gir de rampa";
if s.ID=="Investigadora"
    T.PhaseType(WorkbookRow==22) = "Gir de 180° (rampa)";
end
T.PhaseType(contains(name,"rampa") & contains(name,["pujar","pujada"])) = "Pujada de rampa";
T.PhaseType(contains(name,"rampa") & contains(name,["baixar","baixada"])) = "Baixada de rampa";
T.PhaseType(contains(name,"eslàlom")) = "Eslàlom";
T.PhaseType(contains(name,"porta")) = "Porta manual";
T.PhaseType(contains(name,"ascensor")) = "Ascensor";
T.PhaseType(contains(name,["2mwt","2-minute"]) & ~contains(name,"recuperació")) = "2MWT";
T.PhaseType(contains(name,"acompanyament")) = "Marxa amb acompanyament";
end

function t = registerTime(value,day)
t = NaT(1,1,"TimeZone",day.TimeZone);
if isdatetime(value) && ~isnat(value)
    t = day+timeofday(value);
elseif isduration(value) && ~isnan(seconds(value))
    t = day+value;
elseif isnumeric(value) && isscalar(value) && isfinite(value) && value>=0 && value<1
    t = day+seconds(round(86400*value));
elseif (isstring(value) || ischar(value)) && ~ismissing(string(value))
    parts = split(strip(string(value)),":");
    numbers = str2double(parts);
    if ismember(numel(numbers),[2 3]) && all(isfinite(numbers))
        v = [numbers;0];
        t = day+hours(v(1))+minutes(v(2))+seconds(v(3));
    end
end
end
