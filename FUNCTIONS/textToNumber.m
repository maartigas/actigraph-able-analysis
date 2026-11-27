function x = textToNumber(x)
%TEXTTONUMBER Converteix text numeric amb coma decimal a numero MATLAB.

x = string(x);
x = erase(x, """");
x = strrep(x, ",", ".");
x = str2double(x);
end
