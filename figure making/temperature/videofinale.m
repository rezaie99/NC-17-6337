video = VideoWriter('mavideo.avi');

set(video, 'FrameRate', 20);

open(video);

 [Xq,Yq] = meshgrid(1:.002:8,1:.002:8);


figure('units','normalized','outerposition',[0 0 1/1.6 1])
pause(1)

[M, I]=max(max(max(heatMfinaltemps*4)));

for i=1:1800
    
    Vq = interp2(1:8,1:8,heatMfinaltemps(:,:,i)*4,Xq,Yq,'linear');

%  Vq = interp2(heatMfinaltemps(:,:,i),100);
    
    Vq(:,size(Vq,1)+1)=M*ones(1,size(Vq,1));
    
    Vq(:,size(Vq,1)+2)=-0.5*ones(1,size(Vq,1));
    
   heatmap(Vq);
   colormap(jet(600))
   
   if i<600 
       
       title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
       
  
   elseif i<700
       
   title([num2str((i*100)/1000) ' \heartsuit'],'Color','k','FontSize',22,'FontName','Helvetica');
   
   
   elseif i<800
   
     title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
   
      elseif i<900
       
   title([num2str((i*100)/1000) ' \heartsuit'],'Color','k','FontSize',22,'FontName','Helvetica');
   
   
   elseif i<1000
   
     title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
   
       
      elseif i<1100
       
   title([num2str((i*100)/1000) ' \heartsuit'],'Color','k','FontSize',22,'FontName','Helvetica');
   
   
   elseif i<1200
   
     title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
   
       
      elseif i<1300
       
   title([num2str((i*100)/1000) ' \heartsuit'],'Color','k','FontSize',22,'FontName','Helvetica');
   
   
   elseif i<1400
   
     title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
   
       
      elseif i<1500
       
   title([num2str((i*100)/1000) ' \heartsuit'],'Color','k','FontSize',22,'FontName','Helvetica');
   
   
   elseif i<1600
   
     title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
   
        elseif i<1700
       
   title([num2str((i*100)/1000) ' \heartsuit'],'Color','k','FontSize',22,'FontName','Helvetica');
   
   
   elseif i<1800
   
     title([num2str((i*100)/1000)],'Color','k','FontSize',22,'FontName','Helvetica');
   
       
       
   end
   
   set(gca,'Xtick',1:size(Vq,1)/7:size(Vq,1))
   set(gca,'Ytick',1:size(Vq,1)/7:size(Vq,1))
   set(gca, 'CLim', [0, 10]);
   
   grid on
   colorbar
   F=getframe(gcf);
   
            writeVideo(video,F);
           
end

close(video);
