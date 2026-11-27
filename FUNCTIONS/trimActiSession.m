function [A,phases] = trimActiSession(A,phases,start,stop)
% Interval analític exacte. Es conserven només les èpoques completes.
A.Start = max(A.Start,start);
A.Stop = min(A.Stop,stop);
assert(A.Stop>A.Start,"L'interval analític és buit.");
A.Start.Format = "yyyy-MM-dd HH:mm:ss.SSSSSS";
A.Stop.Format = A.Start.Format;
epoch = seconds(60);
A.Activity = A.Activity(A.Activity.Timestamp>=A.Start & A.Activity.Timestamp+epoch<=A.Stop,:);

A.Wear = A.Wear(A.Wear.Start<A.Stop & A.Wear.Stop>A.Start,:);
A.Wear.Start = max(A.Wear.Start,A.Start);
A.Wear.Stop = min(A.Wear.Stop,A.Stop);
inside = @(t) t>=A.Start & t<A.Stop;
A.Temperature = A.Temperature(inside(A.Temperature.Timestamp),:);
A.Markers = A.Markers(inside(A.Markers.Timestamp),:);
A.HR = A.HR(A.HR.timestamp>=A.Start & A.HR.timestamp+epoch<=A.Stop,:);
A.Breathing = A.Breathing(inside(A.Breathing.timestamp),:);
A.IBI = A.IBI(inside(A.IBI.timestamp),:);
A.HRV = A.HRV(A.HRV.start>=A.Start & A.HRV.("end")<=A.Stop,:);
outside = phases.Usable & (phases.Stop<=A.Start | phases.Start>=A.Stop);
phases.TimeSource(outside) = "Fora_interval_analitzat";
phases.Usable(outside) = false;
phases.Start(outside) = NaT;
phases.Stop(outside) = NaT;
phases.FigureStart(outside) = NaT;
phases.FigureStop(outside) = NaT;
clipped = phases.Usable & (phases.Start<A.Start | phases.Stop>A.Stop);
phases.TimeSource(clipped) = phases.TimeSource(clipped)+"_retall_interval_analitzat";
use = phases.Usable;
phases.Start(use) = max(phases.Start(use),A.Start);
phases.Stop(use) = min(phases.Stop(use),A.Stop);
drawn = use & ~isnat(phases.FigureStart) & ~isnat(phases.FigureStop);
phases.FigureStart(drawn) = max(phases.FigureStart(drawn),A.Start);
phases.FigureStop(drawn) = min(phases.FigureStop(drawn),A.Stop);
end
