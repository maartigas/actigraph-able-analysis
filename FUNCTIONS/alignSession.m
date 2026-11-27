function [E, Sync, Anchors] = alignSession(E,A,Anchors,fitDrift)
% ActiGraph es el rellotge de referencia. Desfasament positiu mou ABLE endavant.
origin = A.Start;
offset = 0;
slope = 0;
heldOutMax = NaN;
fitMax = NaN;
method = "Hora_local_nominal";
if ~isempty(Anchors)
    assert(isa(Anchors.AbleTime,"datetime") && isa(Anchors.ActiTime,"datetime") && ...
        ~isempty(Anchors.AbleTime.TimeZone) && ~isempty(Anchors.ActiTime.TimeZone), ...
        "Els ancoratges necessiten datetimes amb zona horaria.");
    assert(islogical(Anchors.UseForFit) && any(Anchors.UseForFit),"Falten ancoratges d'ajust.");
    x = seconds(Anchors.AbleTime-origin);
    y = seconds(Anchors.ActiTime-Anchors.AbleTime);
    fit = Anchors.UseForFit;
    assert(all(isfinite(x) & isfinite(y)),"Ancoratges amb hores absents.");
    if fitDrift
        assert(nnz(fit)>=2 && numel(unique(x(fit)))>=2,"Calen dos temps d'ajust diferents.");
        coefficients = polyfit(x(fit),y(fit),1);
        slope = coefficients(1);
        offset = coefficients(2);
        method = "Ancoratges_offset_i_deriva";
    else
        offset = median(y(fit));
        method = "Ancoratges_offset";
    end
    assert(1+slope>0,"L'ajust inverteix el rellotge.");
    Anchors.Residual_s = y-(offset+slope*x);
    fitMax = max(abs(Anchors.Residual_s(fit)));
    if any(~fit), heldOutMax = max(abs(Anchors.Residual_s(~fit))); end
end
adjust = @(t) t+seconds(offset+slope*seconds(t-origin));
E.Steps.Timestamp = adjust(E.Steps.TimeABLE);
E.StopAligned = adjust(E.LogEnd);
E.StartAligned = adjust(E.Timers.TimeABLE(1));
E.Steps.Timestamp.Format = "yyyy-MM-dd HH:mm:ss.SSSSSS";

lastMarker = max(A.Markers.Timestamp);
Sync = table(method,origin,offset,slope*1e6,height(Anchors),fitMax,heldOutMax, ...
    60,0.000001,1,lastMarker,E.StopAligned,seconds(lastMarker-E.StopAligned), ...
    height(E.ClockUpdates), ...
    'VariableNames',["Method","OffsetReference","OffsetABLE_s","Drift_ppm","AnchorN", ...
    "FitMaxResidual_s","HeldOutMaxResidual_s", ...
    "ActiLifeEpoch_s","ABLELogTimestampResolution_s","EventMarkerResolution_s", ...
    "LastMarker","ABLEEndAligned","LastMarkerMinusABLEEnd_s","ABLEClockLogEvents"]);
end
