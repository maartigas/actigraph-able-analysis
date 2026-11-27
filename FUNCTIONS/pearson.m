function r = pearson(x,y)
x = x-mean(x);
y = y-mean(y);
denominator = norm(x)*norm(y);
r = NaN;
if denominator>0
    r = dot(x,y)/denominator;
end
end

