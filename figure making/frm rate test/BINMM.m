classdef BINMM
    methods(Static)
      function datatype = getDataType(int)
         
          datatype = 'uint16';
          
          switch int
              case 1
                  datatype = 'uint8';
              case 2
                  datatype = 'uint16';
              case 3
                  datatype = 'int16';
              case 4
                  datatype = 'single';
          end
          
         
      end
      
     function int = getDataTypeInt(datatype)
         
          int = 2;
          
          switch datatype
              case 'uint8'
                  int = 1;
              case 'uint16'
                  int = 2;
              case 'int16'
                  int = 3;
              case 'single'
                  int = 4;
          end
          
         
     end
      
    function nbytes = sizeOf(datatype)
         
        try
            z = zeros(1, datatype); %#ok, we use 'z' by name later.
        catch
            error('Unsupported class for finding size');
        end

        w = whos('z');
        nbytes = w.bytes;
          
         
      end
    end
end