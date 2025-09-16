-- HelpMyBestLife Development Platform Manager Launcher
-- This AppleScript launches the development platform manager

on run
	-- Get the path to the script directory
	set scriptPath to (path to me as text)
	set scriptDir to do shell script "dirname " & quoted form of POSIX path of scriptPath
	
	-- Change to the script directory
	do shell script "cd " & quoted form of scriptDir
	
	-- Check if Python is installed
	try
		do shell script "python3 --version"
	on error
		display dialog "Python 3 is not installed. Please install Python 3.7+ and try again." buttons {"OK"} default button "OK" with icon stop
		return
	end try
	
	-- Check if virtual environment exists, create if not
	do shell script "cd " & quoted form of scriptDir & " && if [ ! -d 'dev-env' ]; then python3 -m venv dev-env; fi"
	
	-- Activate virtual environment and install dependencies if needed
	do shell script "cd " & quoted form of scriptDir & " && source dev-env/bin/activate && python -c 'import psutil' 2>/dev/null || pip install -r requirements.txt"
	
	-- Launch the application
	do shell script "cd " & quoted form of scriptDir & " && source dev-env/bin/activate && python dev-setup.py"
end run
