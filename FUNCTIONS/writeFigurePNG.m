function writeFigurePNG(fig,path,printSize)
% Renderitza fora de OneDrive i copia el fitxer acabat a RESULTATS.
temporaryFile = string(tempname)+".png";
cleanup = onCleanup(@() removeTemporaryPNG(temporaryFile));
drawnow;
if nargin>=3
    % Mida física explícita: Windows pot limitar l'alçada de la finestra.
    fig.PaperUnits = "inches";
    fig.PaperPosition = [0 0 printSize];
    fig.PaperSize = printSize;
    print(fig,temporaryFile,"-dpng","-r150");
else
    exportgraphics(fig,temporaryFile,"Resolution",150);
end
[ok,message] = copyfile(temporaryFile,path,"f");
assert(ok,"No s'ha pogut desar el gràfic %s. %s",path,message);
end

function removeTemporaryPNG(path)
if isfile(path), delete(path); end
end
