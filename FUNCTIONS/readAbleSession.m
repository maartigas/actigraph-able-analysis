function E = readAbleSession(s, exportBinary)
% Llegim el log del controlador. Cada bloc comenca amb el comptador lateral.
path = fullfile(s.Able,s.Log);
if s.ZipMember == ""
    raw = fileread(path);
else
    zip = javaObject('java.util.zip.ZipFile',char(path));
    closeZip = onCleanup(@() zip.close());
    entry = zip.getEntry(char(s.ZipMember));
    assert(~isempty(entry),"No s'ha trobat %s dins %s.",s.ZipMember,path);
    scanner = javaObject('java.util.Scanner',zip.getInputStream(entry),'UTF-8');
    closeScanner = onCleanup(@() scanner.close());
    scanner.useDelimiter('\A');
    raw = char(scanner.next());
    clear closeScanner closeZip
end

pattern = ['(?m)^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}:\d{6})' ...
    ' - \w+ - State: (\w+) - Thread: [^\r\n]+? - Class: Metrics - Function: update_metric' ...
    ' - (\w+): ([-+0-9.eE]+)[ \t]*\r?$'];
tokens = regexp(raw,pattern,'tokens');
assert(~isempty(tokens),"No hi ha metriques update_metric a %s.",path);
rows = string(vertcat(tokens{:}));
time = firmwareTime(rows(:,1),s.Day.TimeZone);
assert(all(dateshift(time,"start","day") == s.Day),"Log d'una altra data.");
metric = rows(:,3);
value = str2double(rows(:,4));
assert(all(isfinite(value)),"Valors de telemetria no numerics.");

batchStart = find(ismember(metric,["total_number_left_steps","total_number_right_steps"]));
assert(~isempty(batchStart) && batchStart(1)==1,"Inici de bloc de passa inesperat.");
group = cumsum(ismember((1:numel(metric))',batchStart));
fields = unique(metric,"stable");
[~,col] = ismember(metric,fields);
assert(height(unique([group,col],"rows"))==numel(metric),"Metriques duplicades dins d'un bloc.");
data = NaN(numel(batchStart),numel(fields));
data(sub2ind(size(data),group,col)) = value;
Steps = array2table(data,"VariableNames",cellstr(fields));
Steps.TimeABLE = time(metric=="number_of_steps");
Steps.StateFirmware = rows(metric=="number_of_steps",2);
Steps.Side = replace(metric(batchStart),["total_number_left_steps","total_number_right_steps"],["L","R"]);
assert(all(Steps.number_of_steps == (1:height(Steps))'),"Comptador ABLE discontinu.");
assert(issorted(Steps.TimeABLE,"strictascend"),"Rellotge del log amb salts o duplicats.");
left = Steps.Side=="L";
assert(isequal(Steps.total_number_left_steps(left),cumsum(ones(nnz(left),1))) && ...
    isequal(Steps.total_number_right_steps(~left),cumsum(ones(nnz(~left),1))), ...
    "Comptador lateral ABLE discontinu.");

% Escala inferida. El log no especifica unitats de longitud/velocitat.
Steps.StepDistance_raw = diff([0; Steps.distance_walked]);
lengthFromSide = Steps.step_length_left;
lengthFromSide(~left) = Steps.step_length_right(~left);
assert(all(Steps.StepDistance_raw >= 0 & abs(Steps.StepDistance_raw-lengthFromSide)<1e-6), ...
    "La distancia acumulada no quadra amb les longituds de passa.");
Steps.StepDistance_m_est = Steps.StepDistance_raw/100;
Steps.DistanceTotal_m_est = Steps.distance_walked/100;
Steps.AverageSpeed_mps_est = Steps.average_speed/100;
Steps = movevars(Steps,["TimeABLE","StateFirmware","Side","number_of_steps"],"Before",1);
E.Steps = Steps;

sent = regexp(raw,['(?m)^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}:\d{6})' ...
    ' - [^\r\n]+? - Sending metric (standing_time|walking_time) with value ([-+0-9.eE]+) to ABLE Care'],'tokens');
E.Timers = table;
if ~isempty(sent)
    rows = string(vertcat(sent{:}));
    E.Timers = table(firmwareTime(rows(:,1),s.Day.TimeZone),rows(:,2),str2double(rows(:,3)), ...
        'VariableNames',["TimeABLE","Metric","Value"]);
end
ending = regexp(raw,['(?m)^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}:\d{6})' ...
    ' - [^\r\n]+? - Command received from user interface: END SESSION'],'tokens','once');
assert(~isempty(ending),"Falta el final de sessio al log.");
E.LogEnd = firmwareTime(string(ending{1}),s.Day.TimeZone);
assert(~isempty(E.Timers) && E.Timers.TimeABLE(1)<=Steps.TimeABLE(1) && ...
    E.LogEnd>Steps.TimeABLE(end),"Les fites del log no cobreixen les passes.");

clock = regexp(raw,['(?m)^(\d{4}-\d{2}-\d{2}_\d{2}:\d{2}:\d{2}:\d{6})' ...
    ' - [^\r\n]+? - (Date and time received\.|System datetime updated)'],'tokens');
rows = reshape(string(vertcat(clock{:})),[],2);
E.ClockUpdates = table(firmwareTime(rows(:,1),s.Day.TimeZone),rows(:,2), ...
    'VariableNames',["TimeABLE","Event"]);

% El .slog aporta context dels estats rebuts per l'app i dels ajustos.
app = fileread(fullfile(s.Able,s.Export,s.Export+".slog"));
hits = regexp(app,['(?m)^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})' ...
    ' \w+ \[ExoskeletonController:_handleStateReception\] -> \|- ([^\r\n]+)'],'tokens');
rows = string(vertcat(hits{:}));
t = datetime(rows(:,1),"InputFormat","yyyy-MM-dd HH:mm:ss.SSS","TimeZone",s.Day.TimeZone);
E.States = table(t,rows(:,2),'VariableNames',["TimeABLECare","State"]);
changes = regexp(app,['(?m)^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})' ...
    ' \w+ \[[^\r\n]+?\] -> (PARAM_\w+) (?:changed|increased|decreased) to ([-+0-9.]+)'],'tokens');
rows = reshape(string(vertcat(changes{:})),[],3);
t = datetime(rows(:,1),"InputFormat","yyyy-MM-dd HH:mm:ss.SSS","TimeZone",s.Day.TimeZone);
E.Parameters = table(t,rows(:,2),str2double(rows(:,3)), ...
    'VariableNames',["TimeABLECare","Parameter","Setting"]);

if exportBinary
    [E.Binary, E.BinaryInfo, E.BinaryFields] = readAbleBinary(fullfile(s.Able,s.Export));
end
end

function t = firmwareTime(raw, zone)
t = datetime(raw,"InputFormat","yyyy-MM-dd_HH:mm:ss:SSSSSS", ...
    "Format","yyyy-MM-dd HH:mm:ss.SSSSSS","TimeZone",zone);
end

