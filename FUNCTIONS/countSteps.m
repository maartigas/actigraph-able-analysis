function [n,d,coverage,use] = countSteps(E,a,b)
use = false(height(E.Steps),1);
n = NaN;
d = NaN;
if isnat(a) || isnat(b)
    coverage = NaN;
    return
end
if b<=a
    n = 0;
    d = 0;
    coverage = 0;
    return
end
lo = max(a,E.StartAligned);
hi = min(b,E.StopAligned);
coverage = max(0,seconds(hi-lo));
if coverage>0
    t = E.Steps.Timestamp;
    use = t>=lo & t<hi;
    n = nnz(use);
    d = sum(E.Steps.StepDistance_m_est(use));
end
end

