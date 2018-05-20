function Test
    delete(allchild(0));
    clear('classes');  %#ok<CLCLS>
    clc;
    
    fig = figure('MenuBar', 'none', 'Name', 'Test', 'NumberTitle', 'off', 'Toolbar', 'none');
    movegui(fig, 'center');
    
    tbx = uicontrol('Parent', fig, 'Position', [20, 20, 100, 24], 'Style', 'edit');
    
    data = Data;
    assignin('base', 'data', data);
    
    binding = Binding(data, 'Number', tbx, 'String', 'Converter', @numToStrConverter);
    setappdata(fig, 'Binding', binding);
end

function result = numToStrConverter(value)
    if ischar(value)
        result = str2double(value);
    elseif isnumeric(value)
        result = num2str(value);
    end
end