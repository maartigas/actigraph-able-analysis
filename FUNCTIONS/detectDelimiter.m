function delimiter = detectDelimiter(line)
%DETECTDELIMITER Detecta si el CSV esta separat per ; o per ,.

if contains(line, ";")
    delimiter = ";";
else
    delimiter = ",";
end
end
