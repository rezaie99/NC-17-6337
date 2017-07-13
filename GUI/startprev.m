function startprev()%handles


global preview;
global AVT;
preview = previewGUI;
if AVT.isWorking==0
   close(preview); 
end


% global AVT;
% try
%     stoppreview(AVT.Obj);
% catch
% end
% try
%     stop(AVT.Obj);
% catch
% end
% 
% try
%     %start(AVT.Obj);
% catch
% end
% handles.hImage = image(zeros(AVT.Height,AVT.Width),'Parent',handles.axes1);
% preview(AVT.Obj,handles.hImage);

end