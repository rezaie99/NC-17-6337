classdef binHDM < handle
    % write a description of the class here.
    properties
        % define the properties of the class here, (like fields of a struct)
        filename = '';
        fid = 0;
        imsize =0;
        hOffset = 0;
        datatype ='';
        datatypesize=0;
        currentind = 0;
        isfuncdata = 0;
    end
    methods
        % methods, including the constructor are defined in this block
        function obj = binHDM(fname,funcdata )
            % class constructor
            obj.fid = fopen(fname,'r');
            pause(1)
            [obj.hOffset obj.imsize obj.datatype] = getBinaryHeader(fname);
            type=BINMM();
            obj.datatypesize=type.sizeOf(obj.datatype);
            if exist('funcdata','var')
                obj.isfuncdata = funcdata;
            else
                obj.isfuncdata = 0;
            end
            fseek(obj.fid,obj.hOffset,'bof');
        end
        
        function im = getFrame(obj,i)
            obj.currentind = i-1;
            if obj.currentind<=obj.imsize(3)-1
                if obj.isfuncdata
                    fseek(obj.fid,obj.hOffset+obj.imsize(1)*obj.imsize(2)*obj.currentind*2*2,'bof');
                    data  = fread(obj.fid,obj.imsize(1)*obj.imsize(2)*2,obj.datatype);
                    im = reshape(data(1:end),[obj.imsize(1) obj.imsize(2)*2]);
                    im = im(:,1:2:end);
                else
                    fseek(obj.fid,obj.hOffset+obj.imsize(1)*obj.imsize(2)*obj.currentind*obj.datatypesize,'bof');
                    im = reshape(fread(obj.fid,obj.imsize(1)*obj.imsize(2),obj.datatype),[obj.imsize(1) obj.imsize(2)]);
                end
            else
                im = 0;
            end
            
        end
        function im = getFrames(obj,Frames)
            obj.currentind = Frames(1)-1;
            if (obj.currentind+numel(Frames)-1)<=obj.imsize(3)-1
                if obj.isfuncdata
                    fseek(obj.fid,obj.hOffset+obj.imsize(1)*obj.imsize(2)*obj.currentind*2*2,'bof');
                    data  = fread(obj.fid,obj.imsize(1)*obj.imsize(2)*2*numel(Frames),obj.datatype);
                    im = reshape(data(1:end),[obj.imsize(1) obj.imsize(2)*2 numel(Frames)]);
                    im = im(:,1:2:end,:);
                else
                    fseek(obj.fid,obj.hOffset+obj.imsize(1)*obj.imsize(2)*obj.currentind*obj.datatypesize,'bof');
                    im = reshape(fread(obj.fid,obj.imsize(1)*obj.imsize(2),obj.datatype),[obj.imsize(1) obj.imsize(2)]);
                end
            else
                im = 0;
            end
            
        end
        
        function im = getNext(obj)
            
            if obj.currentind<obj.imsize(3)
                obj.currentind = obj.currentind+1;
                im = reshape(fread(obj.fid,obj.imsize(1)*obj.imsize(2),obj.datatype),[obj.imsize(1) obj.imsize(2)]);
            else
                im = 0;
            end
        end
        
        function im = getPrev(obj)
            if obj.currentind>0
                obj.currentind = obj.currentind-1;
                fseek(obj.fid,obj.hOffset+obj.imsize(1)*obj.imsize(2)*obj.currentind*obj.datatypesize,'bof');
                im = reshape(fread(obj.fid,obj.imsize(1)*obj.imsize(2),obj.datatype),[obj.imsize(1) obj.imsize(2)]);
            else
                im = 0;
            end
        end
        function delete(obj)
            fclose(obj.fid);
        end
        
    end
end