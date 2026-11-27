function wear = readWearValidation(path)
%READWEARVALIDATION Llegeix intervals Wear/Non-Wear exportats d'ActiLife.

lines = readlines(path);
cleanLines = lower(strtrim(lines));
headerRow = find(startsWith(cleanLines, "date/time start;") | ...
                 startsWith(cleanLines, "date/time start,"), 1);

if ~any(contains(lines(headerRow+1:end), [";Wear;", ";Non-Wear;", ",Wear,", ",Non-Wear,"]))
    wear = table;
    return
end
delimiter = detectDelimiter(lines(headerRow));

opts = detectImportOptions(path, ...
    "Delimiter", delimiter, ...
    "NumHeaderLines", headerRow - 1, ...
    "VariableNamingRule", "preserve");

opts = setvartype(opts, opts.VariableNames, "string");
wear = readtable(path, opts);
wear.Properties.VariableNames = strtrim(wear.Properties.VariableNames);

wear.Start = datetime(wear.("Date/Time Start"), "InputFormat", "dd/MM/yyyy HH:mm");
wear.Stop = datetime(wear.("Date/Time Stop"), "InputFormat", "dd/MM/yyyy HH:mm");
wear.Status = string(wear.("Wear or Non-Wear"));
wear.Length_min = textToNumber(wear.("Length (minutes)"));

wear = wear(:, ["Start", "Stop", "Status", "Length_min"]);
end


