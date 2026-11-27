function plotRawPPG(folder,raw,restStart)
% Auxiliar conservat fora del flux actiu; main.m no crida aquesta funció.
% Per tornar-lo a fer servir, cal reactivar explícitament la lectura del PPG.
% Totes les mostres exportades a 50 Hz, per canal i component.
if isempty(raw), return; end
output = fullfile(folder,"PPG_RAW");
if ~isfolder(output), mkdir(output); end
fields = ["Ir_AC","Ir_DC","Red_AC","Red_DC"];
labels = ["Infrared AC","Infrared DC","Red AC","Red DC"];
colors = [0.10 0.30 0.65;0.10 0.30 0.65;0.75 0.20 0.15;0.75 0.20 0.15];
origin = min(raw.Timestamp);
last = minutes(max(raw.Timestamp)-origin);

for channel = unique(raw.Channel)'
    P = sortrows(raw(raw.Channel==channel,:),"Timestamp");
    x = minutes(P.Timestamp-origin);
    fig = figure("Visible","off","Color","white","Position",[90 90 1550 1100], ...
        "Name","Raw PPG | Channel "+string(channel),"NumberTitle","off");
    cleanup = onCleanup(@() close(fig));
    layout = tiledlayout(fig,4,1,"TileSpacing","compact","Padding","loose");
    axesList = gobjects(4,1);
    for k = 1:numel(fields)
        axesList(k) = nexttile(layout);
        plot(axesList(k),x,P.(fields(k)),"Color",colors(k,:),"LineWidth",0.65, ...
            "DisplayName",fields(k));
        grid(axesList(k),"on");
        ylabel(axesList(k),[labels(k);"Export units"]);
        if k<4, axesList(k).XTickLabel = []; end
    end
    linkaxes(axesList,"x");
    xlim(axesList(1),[0 max(last,1/60)]);
    xlabel(axesList(4),"Time (min)");
    base = fullfile(output,"ppg_raw_channel_"+string(channel));
    writeFigurePNG(fig,base+".png");
    writeEditableFigure(fig,base+".fig");

    % Vista inicial de detall amb les mateixes dades, a l'inici del repòs.
    zoomStart = max(0,minutes(restStart-origin));
    zoomStop = min(last,zoomStart+10/60);
    if zoomStop>zoomStart
        xlim(axesList(1),[zoomStart zoomStop]);
        visible = x>=zoomStart & x<=zoomStop;
        for k = 1:numel(fields)
            values = P{visible,fields(k)};
            values = values(isfinite(values));
            if isempty(values), continue; end
            bounds = [min(values) max(values)];
            margin = max(1,0.05*diff(bounds));
            ylim(axesList(k),bounds+[-1 1]*margin);
        end
        writeFigurePNG(fig,base+"_zoom_rest.png");
    end
    clear cleanup
end
fprintf("PPG original a %s | %d mostres exportades\n",output,height(raw));
end

function writeEditableFigure(fig,path)
temporaryFile = string(tempname)+".fig";
cleanup = onCleanup(@() removeTemporaryFigure(temporaryFile));
drawnow;
savefig(fig,temporaryFile,"compact");
[ok,message] = copyfile(temporaryFile,path,"f");
assert(ok,"No s'ha pogut desar la figura editable %s. %s",path,message);
end

function removeTemporaryFigure(path)
if isfile(path), delete(path); end
end
