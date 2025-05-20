clc
clear
close all

SGE_object = simpleGameEngine("ascii-shrunk.png",16,12,1); 

% define constant symbols
NORMAL_CURSOR = 1;
INSERT_CURSOR = 2;

INTRO_SCREEN = [
    '                                                                          ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                         VIMW - VIM but Worse                            ';
    '~                                                                         ';
    '~                             Version 0.1.0                               ';
    '~                           by Alec Kingsley                              ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '~                                                                         ';
    '                                                                          ';
    '                                                                          ';
  ] + 0;

WIDTH = length(INTRO_SCREEN(1,:));
MSG_SPACE_LEN = 2;
HEIGHT = length(INTRO_SCREEN(:,1)) - MSG_SPACE_LEN;

background = zeros(HEIGHT + MSG_SPACE_LEN,WIDTH) + ' ';

screen = INTRO_SCREEN;

% how many spaces are in a tab
% TODO - make this work with vertical nav
TAB_WIDTH = 4;

drawScene(SGE_object, screen);

cursor_x = 1;
cursor_y = 1;
offset = 0; % the y-offset from the top
line_x = 1;
saved_line_x = 0; % for vertical movement
line = 1;

text_contents = {''};

mode = "NORMAL";

% this represents file being edited
file_name = "not defined";

% position constants
POS_RIGHT_OFF = 12;

% number entry (before things like dd, yy, gg)
% -1 for no entry
number_entry = -1;

symbol_keys = ['''' ';' ',' '.' '-' '/' '=' '\' '[' ']'];
KEYS = ['a':'z' symbol_keys];
layout = dictionary(KEYS', KEYS');

% main loop
key = 'fakekey';
while true
    % this represents whether the screen should be updated.
    updated = true;
    % save last key
    last_key = key;
    if mode == "NORMAL"
        background(cursor_y, cursor_x) = NORMAL_CURSOR;
        position = char(compose("%i,%i-%i",line,cursor_x-1,cursor_x));
        screen(end - 1,end - POS_RIGHT_OFF:end - POS_RIGHT_OFF + length(position) - 1) = position;
        drawScene(SGE_object, background, screen);
        % clear last line (message line)
        screen(end - 1,:) = repmat(' ', 1, WIDTH);
        key = getKey(SGE_object, layout);

        numeric_key = str2double(key);
        if ~isnan(numeric_key) && isreal(numeric_key)
            if number_entry == -1
                number_entry = str2double(key);
            else
                number_entry = number_entry * 10 + str2double(key);
            end
        elseif strcmp(key, 'g') 
            if strcmp(last_key, 'g') && ~(line == max(number_entry, 1) && line_x == 1)
                line = min(max(number_entry, 1), length(text_contents));
                line_x = 1;
                number_entry = -1;
                key = 'consumed';
            end
        elseif strcmp(key, 'd')
            if strcmp(last_key, 'd') && ~(line == 1 && length(text_contents) == 1 && isempty(text_contents{1}))
                to_remove = min(max(number_entry, 1), length(text_contents) - line + 1);
                for i=1:min(max(number_entry, 1), length(text_contents) - line + 1)
                    if length(text_contents) == 1
                        text_contents(1) = {''};
                    else
                        text_contents = deleteLine(text_contents, line);
                        if line > length(text_contents)
                            line = line - 1;
                        end
                    end
                end
                if to_remove > 2
                    msg = sprintf('%i fewer lines', to_remove);
                    screen(end - 1,1:length(msg)) = msg;
                end
                line_x = 1;
                number_entry = -1;
                key = 'consumed';
            end
        else
            INSERT_KEYS = {'i','I','a','A','o','O'};
            if ismember(key,INSERT_KEYS)
                % enter insert mode
                mode = "INSERT";
    
                % handle special inserts
                if strcmp(key, 'i')
                    updated = false;
                elseif strcmp(key, 'I')
                    if ~(line_x == 1 && ~isempty(text_contents{line}) && ~isWhitespace(text_contents{line}(line_x)))
                        line_x = 1;
                        while line_x <= length(text_contents{line}) && isWhitespace(text_contents{line}(line_x))
                            line_x = line_x + 1;
                        end
                    else
                        updated = false;
                    end
                elseif strcmp(key, 'a') && ~isempty(text_contents{line})
                    line_x = line_x + 1;
                elseif strcmp(key, 'A')
                    line_x = length(text_contents{line}) + 1;
                elseif strcmp(key, 'o')
                    text_contents = insertLine(text_contents, line, length(text_contents{line}) + 1);
                    line_x = 1;
                    line = line + 1;
                elseif strcmp(key, 'O')
                    if line > 1
                        text_contents = insertLine(text_contents, line - 1, length(text_contents{line - 1}) + 1);
                    else
                        text_contents = insertLine(text_contents, 0);
                    end
                    line_x = 1;
                end
            elseif (strcmp(key, 'h') || strcmp(key, 'leftarrow')) && line_x > 1
                % move cursor left
                line_x = line_x - 1;
            elseif (strcmp(key, 'l') || strcmp(key, 'rightarrow')) && line_x < length(text_contents{line})
                % move cursor right
                line_x = line_x + 1;
            elseif (strcmp(key, 'j') || strcmp(key, 'downarrow')) && line < length(text_contents)
                % move cursor down a line
                line = line + 1;
                if saved_line_x > 0
                    line_x = min(saved_line_x, length(text_contents{line}));
                else
                    saved_line_x = line_x;
                    line_x = min(line_x, length(text_contents{line}));
                end
                if line_x == 0
                    line_x = 1;
                end
            elseif (strcmp(key, 'k') || strcmp(key, 'uparrow')) && line > 1
                % move cursor up a line
                line = line - 1;
                if saved_line_x > 0
                    line_x = min(saved_line_x, length(text_contents{line}));
                else
                    saved_line_x = line_x;
                    line_x = min(line_x, length(text_contents{line}));
                end
                if line_x == 0
                    line_x = 1;
                end
            elseif strcmp(key, '$') && ~isempty(text_contents{line})
                % move cursor to end of line
                line_x = length(text_contents{line});
            elseif strcmp(key, '^') && ~isempty(text_contents{line})
                % move cursor to start of line (non-whitespace)
                if ~(line_x == 1 && ~isempty(text_contents{line}) && ~isWhitespace(text_contents{line}(line_x)))
                    line_x = 1;
                    while line_x < length(text_contents{line}) && isWhitespace(text_contents{line}(line_x))
                        line_x = line_x + 1;
                    end
                else
                    updated = false;
                end
            elseif strcmp(key, 'x') && ~isempty(text_contents{line})
                text_contents = deleteChar(text_contents, line, line_x);
                % move cursor back if last element
                if line_x == length(text_contents{line}) + 1 && line_x > 1
                    line_x = line_x - 1;
                end
            elseif strcmp(key, 'G') && ~(line == length(text_contents) && line_x == 1)
                line = length(text_contents);
                line_x = 1;
            elseif strcmp(key, ':')
                mode = "CMD";
                updated = false;
            else
                updated = false;
            end
            number_entry = -1;
        end
        vertical_movement = {'uparrow','downarrow','j','k'};
        if ismember(last_key, vertical_movement) && ~ismember(key, vertical_movement)
            saved_line_x = -1;
        end
    elseif mode == "INSERT"
        % set insert text
        screen(end - 1,1:length('--INSERT--')) = '--INSERT--';

        background(cursor_y, cursor_x) = INSERT_CURSOR;
        position = char(compose("%i,%i",line,cursor_x));
        screen(end - 1,end - POS_RIGHT_OFF:end - POS_RIGHT_OFF + length(position) - 1) = position;
        drawScene(SGE_object, screen, background);
        screen(end - 1,:) = repmat(' ', 1, WIDTH);
        
        key = getKey(SGE_object, layout);

        if strcmp(key,'escape')
            % return to NORMAL mode
            mode = "NORMAL";
    
            % clear last line
            screen(end - 1,:) = repmat(' ', 1, WIDTH);

            % move cursor back one
            if line_x > 1
                line_x = line_x - 1;
            else
                updated = false;
            end
        elseif strcmp(key, 'leftarrow') && line_x > 1
            % move cursor left
            line_x = line_x - 1;
        elseif strcmp(key, 'rightarrow') && line_x <= length(text_contents{line})
            % move cursor right
            line_x = line_x + 1;
        elseif strcmp(key, 'downarrow') && line < length(text_contents)
            % move cursor down
            line = line + 1;
            if saved_line_x > 0
                line_x = min(saved_line_x, length(text_contents{line}) + 1);
            else
                saved_line_x = line_x;
                line_x = min(line_x, length(text_contents{line}) + 1);
            end
        elseif strcmp(key, 'uparrow') && line > 1
            line = line - 1;
            if saved_line_x > 0
                line_x = min(saved_line_x, length(text_contents{line}) + 1);
            else
                saved_line_x = line_x;
                line_x = min(line_x, length(text_contents{line}) + 1);
            end
        elseif strcmp(key, 'backspace')
            if line_x > 1
                text_contents = deleteChar(text_contents, line, line_x - 1);
                line_x = line_x - 1;
            elseif line > 1
                line_x = length(text_contents{line - 1}) + 1;
                text_contents = deleteLineBreak(text_contents, line);
                line = line - 1;
            end
        elseif strcmp(key, 'return')
            % go to next line, include rest of current line
            text_contents = insertLine(text_contents, line, line_x);
            line = line + 1;
            line_x = 1;
        elseif length(key) == 1
            % insert character
            text_contents = insertChar(text_contents, line, line_x, key);
            line_x = line_x + 1;
        end
        vertical_movement = {'uparrow','downarrow'};
        if ismember(last_key, vertical_movement) && ~ismember(key, vertical_movement)
            saved_line_x = -1;
        end
    elseif mode == "CMD"
        % clear message area
        screen(end - 1,:) = repmat(' ', 1, WIDTH);
        screen(end - 1,1) = ':';
    
        % hide cursor
        background(cursor_y, cursor_x) = ' ';

        cursor_cmd = 2;

        cmd = '';
        while true
            background(end - 1, cursor_cmd) = INSERT_CURSOR;
            drawScene(SGE_object, screen, background);
            background(end - 1, cursor_cmd) = ' ';
            key = getKey(SGE_object, layout);

            % TODO - add arrow key support
            if strcmp(key, 'return')
                break;
            elseif strcmp(key, 'escape')
                updated = false;
                cmd = '';
                break;
            elseif strcmp(key, 'backspace')
                if cursor_cmd == 2
                    break;
                else
                    screen(end - 1, cursor_cmd - 1) = ' ';
                    cursor_cmd = cursor_cmd - 1;
                    cmd = cmd(1:end - 1);
                end
            elseif length(key) == 1 && length(cmd) < WIDTH - 2
                screen(end - 1, cursor_cmd) = key;
                cursor_cmd = cursor_cmd + 1;
                cmd = [cmd key]; %#ok<AGROW>
            end
        end
        screen(end - 1,:) = repmat(' ',1,WIDTH);

        cmd_args = strsplit(cmd);
        msg = '';
        if strcmp(cmd_args{1}, 'w') || strcmp(cmd_args{1}, 'wq')
            if length(cmd_args) > 1
                file_name = cmd_args{2};
            end
            
            if length(strsplit(file_name)) ~= 1
                msg = 'E32: No file name';
            else
                writeFile(file_name, text_contents);
                if strcmp(cmd_args{1}, 'wq')
                    close all;
                    break;
                else
                    line_ct = length(text_contents);
                    byte_ct = sum(cellfun(@numel, text_contents)) + line_ct;
                    msg = sprintf('"%s" %iL, %iB written', file_name, line_ct, byte_ct);
                end
            end
        elseif strcmp(cmd_args{1}, 'vi') || strcmp(cmd_args{1}, 'vim') || strcmp(cmd_args{1}, 'vimw')
            if length(cmd_args) > 1
                file_name = cmd_args{2};
            end
            
            if length(strsplit(file_name)) ~= 1
                msg = 'E32: No file name';
            elseif exist(file_name, 'file') == 2
                text_contents = loadFile(file_name);
                msg = sprintf('"%s"', file_name);
                line = 1;
                line_x = 1;
                offset = 0;
            else
                text_contents = {''};
                msg = sprintf('"%s" [New]', file_name);
                line = 1;
                line_x = 1;
            end
        elseif strcmp(cmd_args{1}, 'set') && length(cmd_args) == 2
            if strcmp(cmd_args{2}, 'layout=random')
                % if you are using this feature, why????
                layout = dictionary(KEYS', (KEYS(randperm(length(KEYS))))');
                msg = 'Layout randomized. Good luck';
                updated = false;
            elseif strcmp(cmd_args{2}, 'layout=rot13')
                % might as well make SOME "useful" layout changer
                layout = dictionary(KEYS', [circshift('a':'z', 13) symbol_keys]');
                msg = 'Layout set to rot13';
                updated = false;
            elseif strcmp(cmd_args{2}, 'layout=default')
                % if you can even manage to type this
                layout = dictionary(KEYS', KEYS');
                msg = 'Layout set to default';
                updated = false;
            else
                msg = sprintf('E518: Unknown option: %s', cmd_args{2});
            end
        elseif strcmp(cmd_args{1}, 'q') || strcmp(cmd_args{1}, 'q!')
            close all;
            break;
        elseif ~isempty(cmd)
            USED_SPACE = 43;
            if length(cmd) > WIDTH - USED_SPACE
                cmd = [cmd(1:(WIDTH - USED_SPACE - 3)) '...'];
            end
            msg = sprintf('E492: Not an editor command: %s', cmd);
        end
        screen(end - 1,1:length(msg)) = msg;
        mode = "NORMAL";
    end
    if updated
        background(cursor_y, cursor_x) = ' ';
        [screen(1:HEIGHT,:), cursor_x, cursor_y] = buildScreen(text_contents, offset, line, line_x, TAB_WIDTH, WIDTH, HEIGHT);
        
        while ~(1 <= cursor_y && cursor_y <= HEIGHT)
            if cursor_y < 1
                offset = offset - 1;
            else
                offset = offset + 1;
            end
            [screen(1:HEIGHT,:), cursor_x, cursor_y] = buildScreen(text_contents, offset, line, line_x, TAB_WIDTH, WIDTH, HEIGHT);

        end
    end

end

function is_whitespace = isWhitespace(char)
    % checks whether a character is whitespace.
    %
    % Input:
    %   char - the character to test
    % Output:
    %   is_whitespace - true iff char is whitespace
    %

    is_whitespace = char == ' ' || char == sprintf('\t');
end

function key = getKey(SGE_object, layout)
    % symbol values
    SYMBOL_NAMES = {'space', 'comma', 'period', 'semicolon', 'quote',...
        'slash', 'hyphen', 'leftbracket', 'rightbracket', 'equal',...
        'backquote', 'backslash','tab'};
    SYMBOL_VALUES = {' ', ',','.',';','''','/','-','[',']','=','`','\',sprintf('\t')};
    symblify = dictionary(SYMBOL_NAMES, SYMBOL_VALUES);

    key = getKeyboardInput(SGE_object);
    if ismember(key, SYMBOL_NAMES)
        key = symblify({key});
    end
    if ismember(key, keys(layout))
        key = layout({key});
    end
    key = processAlt(key, SGE_object.my_figure);
    key = processShift(key, SGE_object.my_figure);
end

function key = processAlt(key, fig)
    % Applies alt key, if pressed. This is for some special characters.   
    %
    % Input: 
    %   key - the key pressed
    %   fig - the figure for the SGE object
    % Output: 
    %   key - the modified key
    %

    modifiers = get(fig, 'CurrentModifier');
    REGULAR_VALUES = {
        'a','e','i','o','u',...
        'n','y','t','d','g',...
        'c',
    };
    ALT_VALUES = {
        'á','é','í','ó','ú',...
        'ñ','ü','þ','ð','ġ',...
        'ċ',
    };
    key = char(key);
    if ismember('alt',modifiers)
        if ismember(key, REGULAR_VALUES)
            dict = dictionary(REGULAR_VALUES, ALT_VALUES);
            key = dict({key});
        end
    end
    key = char(key);
end

function key = processShift(key, fig)
    % Applies shift key, if pressed.    
    %
    % Input: 
    %   key - the key pressed
    %   fig - the figure for the SGE object
    % Output: 
    %   key - the modified key
    %

    modifiers = get(fig, 'CurrentModifier');
    LOWERCASE_VALUES = {
        '1','2','3','4','5',...
        '6','7','8','9','0',...
        ';','''','/','-','[',...
        ']','=','á','é','í',...
        'ó','ú','ñ','ü','`',...
        '\',',','.','þ','ð',...
        'ġ','ċ',
    };
    UPPERCASE_VALUES = {
        '!','@','#','$','%',...
        '^','&','*','(',')',...
        ':','"','?','_','{',...
        '}','+','Á','É','Í',...
        'Ó','Ú','Ñ','Ü','~',...
        '|','<','>','Þ','Ð',...
        'Ġ','Ċ',
    };
    key = char(key);
    if ismember('shift',modifiers)
        if ismember(key, LOWERCASE_VALUES)
            dict = dictionary(LOWERCASE_VALUES, UPPERCASE_VALUES);
            key = dict({key});
        elseif length(key) == 1 && key <= 'z' && key >= 'a'
            key = key + 'A' - 'a';
        end
    end
    key = char(key);
end

function text_contents = deleteLineBreak(text_contents, line)
    % deletes a line from the model, appends to previous line
    %
    % Input: 
    %   text_contents - cell array of character arrays representing lines
    %   line - the line #
    % Output: 
    %   text_contents - cell array of character arrays representing lines
    %

    text_contents{line - 1} = [text_contents{line - 1} text_contents{line}];
    text_contents(line) = [];

end

function text_contents = deleteLine(text_contents, line)
    % deletes a line from the model
    %
    % Input: 
    %   text_contents - cell array of character arrays representing lines
    %   line - the line #
    % Output: 
    %   text_contents - cell array of character arrays representing lines
    %

    text_contents = [text_contents(1:line - 1); text_contents(line + 1:end)];
end


function text_contents = insertLine(text_contents, line, line_x)
    % inserts a line in the model
    %
    % Input: 
    %   text_contents - cell array of character arrays representing lines
    %   line - the line #
    %   line_x - the x position within the line
    % Output: 
    %   text_contents - cell array of character arrays representing lines
    %

    if line > 0
        part1 = text_contents{line}(1:line_x - 1);
        part2 = text_contents{line}(line_x:end);
        text_contents = [text_contents(1:line-1); {part1}; {part2}; text_contents(line+1:end)];
    else
        text_contents = [{''}; text_contents];
    end

end


function text_contents = deleteChar(text_contents, line, line_x)
    % deletes a character of text_contents at line line at char line_x
    %
    % Input: 
    %   text_contents - cell array of character arrays representing lines
    %   line - the line #
    %   line_x - the x position within the line
    % Output:
    %   text_contents - cell array of character arrays representing lines
    %

    text_contents{line} = [text_contents{line}(1:line_x - 1), text_contents{line}(line_x + 1:end)];
end


function text_contents = insertChar(text_contents, line, line_x, char)
    % inserts a character char in text_contents at line line at char line_x
    %
    % Input: 
    %   text_contents - cell array of character arrays representing lines
    %   line - the line #
    %   line_x - the x position within the line
    %   char - the character to insert
    % Output:
    %   text_contents - cell array of character arrays representing lines
    %

    text_contents{line} = [text_contents{line}(1:line_x - 1) char text_contents{line}(line_x:end)];
end

function [screen, cursor_x, cursor_y] = buildScreen(text_contents, offset, line, line_x, TAB_WIDTH, WIDTH, HEIGHT)
    % builds a screen containing the current state. Returns the cursor_x
    % and cursor_y within that screen.
    %
    % Input: 
    %   text_contents - cell array of character arrays representing lines
    %   offset - the offset from the top to start printing at
    %   line - the line #
    %   line_x - the x position within the line
    %   TAB_WIDTH - the width of a tab
    %   WIDTH - the width of the screen
    %   HEIGHT - the height of the screen
    % Output: 
    %   screen - array of character arrays representing text
    %   cursor_x - x position on screen
    %   cursor_y - y position on screen
    %

    % initialize screen
    screen = zeros(HEIGHT, WIDTH) + ' ';

    % variables ending in '_i' may be modified. i is for index
    cursor_y_i = 1 - offset;
    cursor_x_i = 0;

    % build each line one by one
    for line_i = 1:length(text_contents)
        for line_x_i = 1:(length(text_contents{line_i}) + 1)

            [cursor_y_i, cursor_x_i] = updateCursor(cursor_y_i, cursor_x_i, WIDTH);
            % set cursor_x and cursor_y return values if goal reached
            if line_i == line && line_x_i == line_x
                cursor_x = cursor_x_i;
                cursor_y = cursor_y_i;
            end

            % only include a character if it's in the viewing field
            if inField(cursor_y_i, cursor_x_i, HEIGHT, WIDTH) && line_x_i <= length(text_contents{line_i})
                char = text_contents{line_i}(line_x_i);
                if char == sprintf('\t')
                    while mod(cursor_x_i, TAB_WIDTH) ~= 0
                        [cursor_y_i, cursor_x_i] = updateCursor(cursor_y_i, cursor_x_i, WIDTH);
                        if inField(cursor_y_i, cursor_x_i, HEIGHT, WIDTH)
                            screen(cursor_y_i, cursor_x_i) = ' ';
                        end
                    end
                else
                    screen(cursor_y_i, cursor_x_i) = text_contents{line_i}(line_x_i);
                end
            end
        end
        cursor_y_i = cursor_y_i + 1;
        cursor_x_i = 0;
    end

    % output ~ at the start of remaining lines to indicate they're empty
    while cursor_y_i <= HEIGHT
        screen(cursor_y_i, 1) = '~';
        cursor_y_i = cursor_y_i + 1;
    end
end


function [cursor_y, cursor_x] = updateCursor(cursor_y, cursor_x, WIDTH)
    % moves the cursor to the next position. Might be one to the right,
    % or start on the next line.
    %
    % Input:
    %   cursor_y - y position of cursor
    %   cursor_x - x position of cursor
    %   WIDTH - width of board
    % Output:
    %   cursor_y - y position of cursor
    %   cursor_x - x position of cursor
    %

    cursor_x = cursor_x + 1;
    if cursor_x > WIDTH
        cursor_x = 1;
        cursor_y = cursor_y + 1;
    end

end

function in_field = inField(y, x, MAX_Y, MAX_X)
    % determines whether y is within (1, MAX_Y) and x is within (1, MAX_X)
    %
    % Input: 
    %   y - y position
    %   x - x position
    %   MAX_Y - max y position
    %   MAX_X - max x position
    % Output: 
    %   true iff point is on field
    %

    in_field = (1 <= x && x <= MAX_X) && (1 <= y && y <= MAX_Y);
end

function text_contents = loadFile(file_name)
    % open the file named file_name and read it to text_contents.
    %
    % Input:
    %   file_name - the name of the file to read from
    % Output:
    %   text_contents - a cell array of character arrays of the lines

    % open the file for reading
    fid = fopen(file_name, 'r');
    
    % check if the file opened successfully
    if fid == -1
        error('Could not open file %s for reading.', file_name);
    end
    
    % read each line into a cell array
    text_contents = {};
    line = fgetl(fid);
    while ischar(line)
        text_contents{end+1, 1} = line; %#ok<AGROW>
        line = fgetl(fid);
    end
    
    % close the file
    fclose(fid);
end

function writeFile(file_name, text_contents)
    % open the file named file_name and write text_contents to it.
    %
    % Input:
    %   file_name - the name of the file to read from
    %   text_contents - a cell array of character arrays of the lines
    
    % open the file for writing
    fid = fopen(file_name, 'w');
    
    % check if the file opened successfully
    if fid == -1
        error('Could not open file %s for writing.', file_name);
    end
    
    % write each line from the cell array to the file
    for i = 1:length(text_contents)
        fprintf(fid, '%s\n', text_contents{i});
    end
    
    % close the file
    fclose(fid);
end

