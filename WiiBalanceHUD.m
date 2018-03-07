classdef WiiBalanceHUD < handle
% Helper class for WiiBalance.m (Displays balance data in a GUI)
%
% @Requires: WiiBalance.m
%   
% @Constructor Parameters:              
%
%       <none>
%
% @Example:         s=WiiBalanceHUD(50);
%                   for i=1:500, s = s.Update(rand(2,1)*5); end
%
%                   s=WiiBalanceHUD(50,10);
%                   for i=1:500, s = s.Update(rand(2,1)*5); end
%
% @See also:        
%
% @Earliest compatible Matlab version: v2012
%
% @Author:          Pete R Jones
%
% @Creation Date:	15/04/11
% @Last Update:     07/03/18
%
% @Verinfo:
%   0.0.1	PJ	13/10/2016 : first_build\n
%   0.0.2	PJ	07/03/2018 : Added additional info to help text\n
%
% Copyright 2018 : P R Jones <petejonze@gmail.com>
% *********************************************************************
%

    properties
        %<none>
    end
    properties (Constant)
        %<none>
    end
    properties (GetAccess = 'private', SetAccess = 'private')
        %
        Fs
        % data vector(s)
        cogXHistory
        cogYHistory
        maxNPointsToDisp
        % figure handles
        hFig
        hBalance
        hTimeX
        hTimeY
    end
    properties (Dependent)
        %<none>
    end
    methods
        %Constructor
        function obj=WiiBalanceHUD(Fs, duration) %specifying duration too saves having to update x axis, so might run a bit quicker 
            % set specified parameter values
            obj.Fs = Fs;
            
            obj.cogXHistory = [];
            obj.cogYHistory = [];
            
            % open up figure
            obj.hFig = figure('Position', [680   355   425   625]);
            subplot(3,2,1);
            obj.hBalance = plot(NaN, NaN, 'o');
            grid on
            axis manual
            axis([-10 10 -10 10]);
            xlabel('x'); ylabel('y');
            
            subplot(3,2,3:4);
            obj.hTimeX = plot(NaN, NaN, '-');
            xlabel('Time (sec)'); ylabel('COG x');
            if nargin>1 && ~isempty(duration)
                axis manual
                axis([0 duration -10 10]);
            end
            
            subplot(3,2,5:6);
            obj.hTimeY = plot(NaN, NaN, '-');
            xlabel('Time (sec)'); ylabel('COG y');
            if nargin>1 && ~isempty(duration)
                axis manual
                axis([0 duration -10 10]);
            end
            
            obj.maxNPointsToDisp = floor(duration*Fs);
        end
                
        function obj = Update(obj,xy)
             set(obj.hBalance,'XData',xy(1),'YData',xy(2))

             obj.cogXHistory = [obj.cogXHistory xy(1)];
             obj.cogYHistory = [obj.cogYHistory xy(2)];
             
             x0 = max(1,(length(obj.cogXHistory)-obj.maxNPointsToDisp));
             x = (x0:length(obj.cogXHistory))/obj.Fs;

             set(obj.hTimeX, 'XData',x, 'YData',obj.cogXHistory(x0:end))
             set(obj.hTimeY,'XData',x,'YData',obj.cogYHistory(x0:end))
             
             % update axes
             xaxis = get(obj.hTimeX,'Parent');
             set(xaxis, 'XLim',[min(x) max(max(get(xaxis,'Xlim')),max(x))]);
             yaxis = get(obj.hTimeY,'Parent');
             set(yaxis, 'XLim',[min(x) max(max(get(yaxis,'Xlim')),max(x))]);
             
             drawnow();
        end
        
     	function obj = Clear(obj)
             set(obj.hBalance,'XData',NaN,'YData',NaN)
             
             obj.cogYHistory = [];
             set(obj.hTimeX,'XData',NaN,'YData',NaN)
             set(obj.hTimeY,'XData',NaN,'YData',NaN)
             
             drawnow();
        end
        
        function SetFocus(obj)
             figure(obj.hFig);
             drawnow();
        end
    end % end public methods
    methods (Static)
        %<none>
    end
    methods(Access = private)
        %<none>
    end
end