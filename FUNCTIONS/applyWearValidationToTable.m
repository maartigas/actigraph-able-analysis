function T = applyWearValidationToTable(T, timeVariable, wear)
%APPLYWEARVALIDATIONTOTABLE Marca files d'una taula com Wear/Non-Wear.

T.IsWear = false(height(T), 1);

if isempty(T)
    return
end

if isempty(wear)
    T.IsWear(:) = true;
    return
end

times = T.(timeVariable);

for k = 1:height(wear)
    if wear.Status(k) == "Wear"
        idx = times >= wear.Start(k) & times < wear.Stop(k);
        T.IsWear(idx) = true;
    end
end
end
