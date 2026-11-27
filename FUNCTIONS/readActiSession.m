function A = readActiSession(s)
% Els lectors de fisiologia i wear necessaris s'inclouen a FUNCTIONS.
day = s.Day;
zone = day.TimeZone;
A.Wear = readWearValidation(oneFile(s.Acti,"Wear_Validation*.csv"));
assert(~isempty(A.Wear),"No hi ha intervals wear validats.");
A.Wear.Start.TimeZone = zone;
A.Wear.Stop.TimeZone = zone;

A.Activity = readActivity(oneFile(s.Acti,"*60secDataTable.csv"),zone);
A.Start = A.Activity.Timestamp(1);
A.Stop = A.Activity.Timestamp(end)+seconds(60);
A.Activity.IsWear = false(height(A.Activity),1);
wear = sortrows(A.Wear(A.Wear.Status=="Wear",:),"Start");
assert(all(wear.Start(2:end)>=wear.Stop(1:end-1)),"Els intervals de wear se solapen.");
for i = 1:height(wear)
    A.Activity.IsWear = A.Activity.IsWear | ...
        (A.Activity.Timestamp>=wear.Start(i) & A.Activity.Timestamp+seconds(60)<=wear.Stop(i));
end

A.Temperature = applyWearValidationToTable( ...
    readSignal(oneFile(s.Acti,"*Temperature.csv"),zone),"Timestamp",A.Wear);
% PPG cru vermell/IR desactivat: es conserva el codi per a una revisió futura.
% ppg = readSignal(oneFile(s.Acti,"*ppg50hz.csv"),zone);
% A.PPGRaw = ppg(:,["Timestamp","Channel","Ir_AC","Ir_DC","Red_AC","Red_DC"]);
A.Markers = readSignal(oneFile(s.Acti,"*eventmarkers.csv"),zone);

p = fullfile(s.Acti,s.HR);
A.HR = readActiCsvSimple(fullfile(p,"HeartRate.csv"));
A.HR.timestamp = physTime(A.HR.timestamp,day);
% El camp timestamputc es un control independent del fus emprat a l'export.
localAsUTC = A.HR.timestamp;
localAsUTC.TimeZone = "UTC";
assert(all(timeofday(localAsUTC)==duration(extractBetween(string(A.HR.timestamputc),5,12), ...
    "InputFormat","hh:mm:ss")),"L'hora UTC d'HR no quadra amb l'hora local.");
A.HR = applyWearValidationToTable(A.HR,"timestamp",A.Wear);
A.Breathing = readActiCsvSimple(fullfile(p,"BreathingRate.csv"));
A.Breathing.timestamp = physTime(A.Breathing.timestamp,day);
A.Breathing = applyWearValidationToTable(A.Breathing,"timestamp",A.Wear);
A.IBI = readActiCsvSimple(fullfile(p,"InterBeatInterval.csv"));
A.IBI.timestamp = physTime(A.IBI.timestamp,day);
A.IBI = applyWearValidationToTable(A.IBI,"timestamp",A.Wear);
A.HRV = readActiCsvSimple(fullfile(p,"HeartRateVar.csv"));
A.HRV.start = physTime(A.HRV.start,day);
A.HRV.("end") = physTime(A.HRV.("end"),day);
assert(all(seconds(A.HRV.("end")-A.HRV.start)==A.HRV.window_size_seconds), ...
    "Durada HRV inconsistent.");
A.HRV.FullWear = false(height(A.HRV),1);
for i = 1:height(A.Wear)
    if A.Wear.Status(i)=="Wear"
        A.HRV.FullWear = A.HRV.FullWear | ...
            (A.HRV.start>=A.Wear.Start(i) & A.HRV.("end")<=A.Wear.Stop(i));
    end
end
end

function path = oneFile(folder,pattern)
files = dir(fullfile(folder,pattern));
assert(isscalar(files),"Cal un unic %s a %s.",pattern,folder);
path = fullfile(folder,string(files.name));
end

function T = readSignal(path,zone)
row = headerRow(path,"Timestamp,");
options = detectImportOptions(path,"Delimiter",",","NumHeaderLines",row-1, ...
    "VariableNamingRule","preserve");
options = setvartype(options,options.VariableNames(2:end),"double");
options = setvartype(options,"Timestamp","string");
T = readtable(path,options);
T.Timestamp = datetime(T.Timestamp,"InputFormat","yyyy-MM-dd HH:mm:ss.SSS", ...
    "Format","yyyy-MM-dd HH:mm:ss.SSS","TimeZone",zone);
end

function T = readActivity(path,zone)
% Counts i magnitud vectorial de les epoques de 60 s.
row = headerRow(path,"Date,");
metadata = readlines(path);
assert(contains(metadata(1),"Filter Normal") && ...
    any(startsWith(metadata(1:row-1),"Epoch Period") & contains(metadata(1:row-1),"00:01:00")), ...
    "Cal un export ActiLife amb filtre Normal i èpoques de 60 segons.");
options = detectImportOptions(path,"Delimiter",",","NumHeaderLines",row-1, ...
    "VariableNamingRule","preserve");
options = setvartype(options,options.VariableNames,"string");
U = readtable(path,options);
U.Properties.VariableNames = strtrim(U.Properties.VariableNames);
t = datetime(U.Date+" "+U.Time,"InputFormat","dd/MM/yyyy HH:mm:ss","TimeZone",zone);
assert(~isempty(t) && all(diff(t)==seconds(60)), ...
    "Els timestamps de l'export han de ser consecutius i separats per 60 s.");
T = table(t,textToNumber(U.Axis1),textToNumber(U.Axis2),textToNumber(U.Axis3), ...
    textToNumber(U.("Vector Magnitude")), ...
    'VariableNames',["Timestamp","Axis1_CPM","Axis2_CPM","Axis3_CPM","VM_CPM"]);
axesCPM = T{:,["Axis1_CPM","Axis2_CPM","Axis3_CPM"]};
assert(all(abs(vecnorm(axesCPM,2,2)-T.VM_CPM)<=0.011), ...
    "La VM exportada no quadra amb els counts dels tres eixos.");
end

function row = headerRow(path,prefix)
fid = fopen(path,"rt");
assert(fid>=0,"No s'ha pogut obrir %s",path);
cleanup = onCleanup(@() fclose(fid));
for row = 1:30
    line = fgetl(fid);
    if ~ischar(line), break; end
    if startsWith(strtrim(line),prefix,"IgnoreCase",true), return; end
end
error("Capcalera %s absent a %s.",prefix,path);
end

function t = physTime(raw,day)
raw = string(raw);
week = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
d = extractBefore(raw,4);
assert(all(d==week(weekday(day))),"Canvi de dia inesperat a l'export fisiologic.");
stamp = string(day,"yyyy-MM-dd")+" "+extractAfter(raw,4);
t = datetime(stamp,"InputFormat","yyyy-MM-dd HH:mm:ssZ","TimeZone",day.TimeZone);
assert(all(timeofday(t)==duration(extractBetween(raw,5,12),"InputFormat","hh:mm:ss")), ...
    "L'offset de fisiologia no correspon al fus de la sessio.");
end

