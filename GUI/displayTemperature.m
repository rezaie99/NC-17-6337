function displayTemperature(T)
global A0;
global A1;
global A2;
global A3;
set(A0,'String', '-');
set(A1,'String', '-');
set(A2,'String', '-');
set(A3,'String', '-');
for i=1:1:length(T)
    switch i
        case 1
            set(A0,'String', num2str(T(1)));
        case 2
            set(A1,'String', num2str(T(2)));
        case 3
            set(A2,'String', num2str(T(3)));
        case 4
            set(A3,'String', num2str(T(4)));
    end
end
end