function [buttonPressed]= isButtonPressedP(wiimote, ButtonToCheck)
% usage:	      isButtonPressed(ButtonToCheck)
%                 Possible Buttons :: A B UP RIGHT DOWN LEFT PLUS MINUS HOME
%                                   ONE TWO
% purpose:		Tests to see if a button is being pressed
% return:		boolean value (true(1) or false(0)) indicating if the button is pressed
   
wiimote.GetButtonsState();

% check if the button is pressed based on the ButtonToCheck input
switch(upper(ButtonToCheck))
    case 'A'
        buttonPressed = wiimote.Buttons.A;
    case 'B'
        buttonPressed = wiimote.Buttons.B;
    case 'UP'
        buttonPressed = wiimote.Buttons.Up;
    case 'RIGHT'
        buttonPressed = wiimote.Buttons.Right;
    case 'DOWN'
        buttonPressed = wiimote.Buttons.Down;
    case 'LEFT'
        buttonPressed = wiimote.Buttons.Left;
    case 'PLUS'
        buttonPressed = wiimote.Buttons.Plus;
    case 'MINUS'
        buttonPressed = wiimote.Buttons.Minus;
    case 'HOME'
        buttonPressed = wiimote.Buttons.Home;
    case 'ONE'
        buttonPressed = wiimote.Buttons.One;
    case 'TWO'
        buttonPressed = wiimote.Buttons.Two;
    otherwise
        % Bad input
        error('Bad input to isButtonPressed, must be one of the following: A B UP RIGHT DOWN LEFT PLUS MINUS HOME ONE TWO');
end
