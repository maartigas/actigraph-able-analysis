function [binary, info, schema] = readAbleBinary(folder)
% Decodificacio exploratoria del format capcalera + registres big-endian.
% El primer camp sembla Q16.16. Es conserva com a rellotge intern relatiu.
files = dir(folder);
files = files(~[files.isdir]);
files = files(~contains(string({files.name}),"."));
binary = struct([]);
info = table;
schema = table;
for i = 1:numel(files)
    file = string(files(i).name);
    fid = fopen(fullfile(folder,file),"rb");
    assert(fid>=0,"No s'ha pogut obrir %s",file);
    cleanup = onCleanup(@() fclose(fid));
    pieces = split(strip(string(fgetl(fid))),";");
    spec = split(pieces(pieces~=""),":");
    assert(size(spec,2)==5 && spec(1,1)=="Timestamp","Capcalera ABLE inesperada.");
    width = str2double(spec(:,3));
    signed = spec(:,4)=="1";
    scale = str2double(spec(:,5));
    assert(all(ismember(width,1:4) & isfinite(scale)),"Esquema binari desconegut.");
    nBytes = sum(width);
    payload = fread(fid,Inf,"*uint8");
    n = floor(numel(payload)/nBytes);
    bytes = reshape(payload(1:n*nBytes),nBytes,n);
    v = zeros(n,numel(width));
    offset = 0;
    for j = 1:numel(width)
        w = width(j);
        u = ((256.^((w-1):-1:0))*double(bytes(offset+(1:w),:)))';
        if signed(j)
            negative = u >= 2^(8*w-1);
            u(negative) = u(negative)-2^(8*w);
        end
        v(:,j) = u./10^scale(j);
        offset = offset+w;
    end
    tick = v(:,1)/65536;
    zeroRow = ~any(bytes,1)';
    names = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(cellstr(spec(:,1))));
    binary(i).File = file;
    binary(i).Samples = array2table(v,"VariableNames",names);
    binary(i).Samples.InternalTime_s_candidate = tick;
    binary(i).Samples.AllZeroRecord = zeroRow;
    info = [info; table(file,n,nBytes,mod(numel(payload),nBytes),nnz(zeroRow), ...
        nnz(diff(tick)<0),nnz(diff(tick)==0),min(tick),max(tick), ...
        'VariableNames',["File","Records","BytesPerRecord","TrailingBytes","ZeroRecords", ...
        "BackwardJumps","RepeatedTicks","MinInternal_s_candidate","MaxInternal_s_candidate"])];
    if isempty(schema)
        schema = table(spec(:,1),spec(:,2),width,signed,scale,string(names(:)), ...
            'VariableNames',["Field","Unit","Bytes","Signed","DecimalPlaces","MATName"]);
    else
        assert(isequal(spec(:,1),schema.Field) && isequal(width,schema.Bytes) && ...
            isequal(spec(:,2),schema.Unit) && isequal(signed,schema.Signed) && ...
            isequal(scale,schema.DecimalPlaces),"Els fitxers tenen esquemes diferents.");
    end
    clear cleanup
end
end

