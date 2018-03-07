classdef WiiBalance < handle
    % Matlab binding for Wii Balance board, using WiiLab.
    %
    %   Requires the WiiLab toolbox to be installed, and for the balance
    %   board to be paired with the computer (e.g., via the Toshiba
    %   bluetooth stack). Note that this file also requires
    %   WiiBalanceHUD.m.
    %
    %   Further details on how to setup and use:
    %
    %       1. Purchase relevant hardware (bluetooth dongle):
    %           To use balance bord, use WiiLab together with a basic
    %           bluetooth dongle (e.g., I use a "CSR 4.0 Bluetooth Dongle",
    %           purchased for £3 on eBay. Note that the Mayflash DolphinBar
    %           (which is a combination Bluetooth adapter and Sensor Bar)
    %           is *not* appropriate, as it doesn't expose any of the
    %           Bluetooth information to the operating system (instead
    %           sending HID packets directly to Dolphin without a Bluetooth
    %           Stack, thus allowing -TR support, syncing of Wii Remotes,
    %           and other features).
    %
    %       2. Install software for interfacing with bluetooth dongle:
    %           I used the "Toshiba Bluetooth Stack", as detailed here:
    %           https://gbatemp.net/threads/wii-u-pro-controller-to-pc-program-release.343159/page-13
    %
    %       3. Download and install WiiLab library:
    %           As detailed in the paper "WiiLab: Bringing together the
    %           Nintendo Wiimote and MATLAB", by Brindza et al. (2009). To
    %           install:
    %               i. Copy to Program Files (e.g., C:\Program Files (x86)\WiiLAB)
    %               ii. Run InstallWiiLab_32.bat AS ADMINISTRATOR
    %               iii. Test by running WiiLAB\WiiLAB_Matlab\DemoPrograms\AccelMove.m
    %
    %       4. Modify WiiLab as necessary:
    %           If later on you experience errors of the form:
    %               "Getting the 'wm' property of the 'Wiimote' class is
    %               not allowed",
    %           then simply modify the Wiilab file "Wiimote.m", and make
    %           "wm" a public variable
    %
    %       5.  To run:
    %       	i. Make sure running 32 bit matlab (e.g., current Wiilab dll's are only 32 bit), and that wiilab is on path
    %       	ii. Before running Matlab, add connection to bluetooth:
    %               > right click on bluetooth icon in tray (bottom right)
    %               > Add new connection
    %               > Press red button on Wiiboard to ensure detectable
    %               > Select device (e.g., "RVL-WBC-01")
    %               > Click OK
    %           iii. Run Matlab, e.g. "WiiBalance.runExample(1)"
    %
    % Requires the following files: WiiBalanceHUD.m
    %
    % WiiBalance Methods:
    %   * WiiBalance            - WiiBalance Constructor.
    %   * update                - Query balance board for latest data sample.
    %   * saveAndClearAllData	- Save buffer_all to .mat file, and clear buffer.
    %   * saveAndClearTrialData	- Save buffer_trial to .mat file, and clear buffer.
    %
    % Public Static Methods:
    %   * runExample            - Minimal-working-example(s) of use
    %
    % Examples of use:
    %   WiiBalance.runExample(1)
    %   WiiBalance.runExample(2)
    %
    % Earliest compatible Matlab version: v2008
    %
    % Author:
    %   Pete R Jones <petejonze@gmail.com>
    %
    % Verinfo:
    %   0.0.1	PJ	13/10/2016 : first_build\n
    %   0.0.2	PJ	07/03/2018 : Added additional info to help text\n
    %
    % Copyright 2018 : P R Jones <petejonze@gmail.com>
    % *********************************************************************
    %
     
    %% ====================================================================
    %  -----PROPERTIES-----
    %$ ====================================================================      

    properties (GetAccess = public, SetAccess = private)
        % internal handle to Wii Balanceboard
        bb
        
        % expected (approximate) sampling rate, in hertz
        Fs = 44;
        
        % internal data storage parameters
        headers = {'COGx','COGy', 'Sensor1State','Sensor2State','Sensor3State','Sensor4State', 'BatteryState', 'Timestamp'};      
        buffer_all
        buffer_trial
        
        % internal GUI parameters
        useGUI = true;
        myBalanceHUD
    end

    
 	%% ====================================================================
    %  -----PUBLIC METHODS-----
    %$ ====================================================================
    
    methods (Access = public)
        
        %% == CONSTRUCTOR =================================================
        
        function obj = WiiBalance(useGUI)
            % WiiBalance Constructor.
            %
            % @param    useGUI          logical
            % @return   WiiBalance  	WiiBalance object handle
            %
            % @date     13/10/16
            % @author   PRJ
            %
            
                % check/validate
                if ~strcmpi(computer, 'PCWIN')
                    error('WiiBalance only supports 32-bit Windows');
                end
                
                % parse inputs
                if nargin>=1 && ~isempty(useGUI)
                    obj.useGUI = useGUI;
                end
                
                % print update to console
                fprintf('\n\n**Initialising balance board**\n\n');

                % in case didn't close down properly previously:
                try
                    disconnectAllWiimotes();
                catch
                    %warning('No wiimotes to disconnect')
                end
                
                % initialise balance board connection
                obj.bb = Wiimote();
                obj.bb.Connect();

                % If there was a problem connecting to the wiimote
                % Specifically, There are wiimotes connected to the computer but they are
                % connected to another object
                if(obj.bb.isConnected == 0)
                    % Disconnect all the wiimotes on this computer
                    disp('Removing all connected wiimotes...');
                    obj.bb.DisconnectAllWiimotes();
                    % Retry the connection
                    disp('Attempting to connect...');
                    obj.bb = Wiimote();
                    obj.bb.Connect();
                end
                
                % initialise data stores
                nColumns = length(obj.headers);
                % initialise long buffer
                expectedNRows = 10000;
                obj.buffer_all = CExpandableBuffer(expectedNRows, nColumns);
                % initialise short, temporary buffer
                expectedNRows = 1000;
                obj.buffer_trial = CExpandableBuffer(expectedNRows, nColumns);
                
                % wait for user input
                fprintf('Press A on balance board..   ');
                while ~isButtonPressedP(obj.bb,'A')
                    WaitSecs(0.001);
                end
                fprintf('Success.\n\n');

                % open graphical balance display
                if obj.useGUI
                    obj.myBalanceHUD = WiiBalanceHUD(obj.Fs, 10); % open figure, by default show 10 second window
                    obj.myBalanceHUD.Clear();
                    obj.myBalanceHUD.SetFocus(); %set focus on figure
                end

        end
  
        function delete(obj)
            % WiiBalance Destructor.
            %
            % @date     13/10/16
            % @author   PRJ
            %
            try
                obj.bb.DisconnectAllWiimotes();
            catch ME
                fprintf('FAILED TO DISCONNECT WIIBALANCE???\n');
                disp(ME)
            end
            
            % not necessary, but nice:
            obj.bb.wm.release();
            obj.bb.delete();
        end
        
        %% == METHODS =================================================

        function [] = update(obj, warnIfEmpty)
          	% Query balance board for latest data sample.
            %
            %   Also clear trials data(!!)
            %
            % @param    warnIfEmpty     logical (set false to silence)
            %
            % @date     13/10/16
            % @author   PRJ
            %
            if nargin<2 || isempty(warnIfEmpty)
                warnIfEmpty = true;
            end
            
            % get data
            CoG         = obj.bb.wm.GetBalanceBoardCoGState();
            Sensors     = obj.bb.wm.GetBalanceBoardSensorState();
            Battery     = obj.bb.wm.GetBatteryState();
            timestamp   = GetSecs();
            data        = [CoG Sensors Battery timestamp];
            
            % check new
            isNew = true;
            if obj.buffer_all.nrows > 0
                prev = obj.buffer_all.getLastN(1, 1:7);
                if all(prev == data(1:7))
                    if warnIfEmpty
                        warning('WiiBalance:DuplicateData', 'Duplicate data detected. Ignoring. Querying too fast?')
                    end
                    isNew = false;
                end
            end
            
            % store
            if isNew
                obj.buffer_all.put(data);
                obj.buffer_trial.put(data);
            end
            
            % updateGraphics
            if obj.useGUI
                obj.myBalanceHUD.Update(CoG);
            end
        end
        
        function [] = saveAndClearAllData(obj, fn)
            % Save buffer_all to .mat file, and clear buffer.
            %
            % @param    fn     file name (including optional path)
            %
            % @date     13/10/16
            % @author   PRJ
            %
            
            % establish file name
            if nargin<2 || isempty(fn)
                fn = sprintf('WiiBalance_AllData-%s',datestr(now(),30));
            end

            % get data as matrix
            data.matrix.x = obj.buffer_all.get();
            data.matrix.headers = obj.headers;
            
            % convert matrix to structure
            data.struct = struct();
            for i = 1:length(obj.headers)
                data.struct.(obj.headers{i}) = data.matrix.x(:,i);
            end
            
            % save data
            save(fn, 'data')
            
            % clear data buffer
            obj.buffer_all.clear();
            obj.buffer_trial.clear();
        end
        
        function [] = saveAndClearTrialData(obj, fn)
            % Save buffer_trial to .mat file, and clear buffer.
            %
            % @param    fn     file name (including optional path)
            %
            % @date     13/10/16
            % @author   PRJ
            %
            
            % establish file name
            if nargin<2 || isempty(fn)
                fn = sprintf('WiiBalance_TrialData-%s',datestr(now(),30));
            end
            
            % get data as matrix
            data.matrix.x = obj.buffer_trial.get();
            data.matrix.headers = obj.headers;
            
            % convert matrix to structure
            data.struct = struct();
            for i = 1:length(obj.headers)
                data.struct.(obj.headers{i}) = data.matrix.x(:,i);
            end
            
            % save data
            save(fn, 'data')
            
            % clear data buffer
            obj.buffer_trial.clear();
        end

    end

 	%% ====================================================================
    %  -----PRIVATE METHODS-----
    %$ ====================================================================
    
    methods (Access = private)
        
    end
    
    

   	%% ====================================================================
    %  -----STATIC METHODS (public)-----
    %$ ====================================================================
      
    methods (Static, Access = public)

        function [] = runExample(exampleN)
            % Minimal-working-example(s) of use
            %
            % @param    exampleN	Example to run [1|2]. Defaults to 1.
            %
            % @date     13/10/16
            % @author   PRJ
            %
            
            % parse inputs: if no example specified, run example 1
            if nargin<1 || isempty(exampleN)
                exampleN = 1;
            end

            % run selected example
            switch exampleN
                case 1 % default behaviour
                    wii = WiiBalance();
                    
                    % record for 3 seconds
                    fprintf('Recording..')
                    t = GetSecs();
                    tic()
                    while (GetSecs()-t) < 2
                        cycleStart_sec = GetSecs();
                        
                        % query the wii for data
                        wii.update();
                        
                        % pause before continuing cycle (subtracting the time
                        % taken to process this loop itself)
                        cycleDur_sec = GetSecs()-cycleStart_sec;
                        WaitSecs(1/wii.Fs - cycleDur_sec);
                    end
                    fprintf(' Success\n\n')
                    toc()
                    
                    % save data
                    wii.saveAndClearTrialData();
                    wii.saveAndClearAllData();
                    
                    % clear memory
                    wii.delete();
                case 2 % suppress warnings and figures
                    wii = WiiBalance(false);
                    
                    % record for 3 seconds
                    fprintf('Recording..')
                    t = GetSecs();
                    tic()
                    while (GetSecs()-t) < 2
                        cycleStart_sec = GetSecs();
                        
                        % query the wii for data
                        wii.update(false);
                        
                        % pause before continuing cycle (subtracting the time
                        % taken to process this loop itself)
                        cycleDur_sec = GetSecs()-cycleStart_sec;
                        WaitSecs(1/wii.Fs - cycleDur_sec);
                    end
                    fprintf(' Success\n\n')
                    toc()
                    
                    % save data
                    wii.saveAndClearTrialData();
                    wii.saveAndClearAllData();
                    
                    % clear memory
                    wii.delete();
                otherwise
                    error('Specified example not recognised.\n\nTo run, type:\n   WiiBalance.runExample(n)\nwhere n is an integer %i..%i\n\nE.g., QP = QuestPlus.runExample(1);', 1, 2);
            end
        end
    end
  
end