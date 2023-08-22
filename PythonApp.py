import serial
import matplotlib.pyplot as plt
import xlsxwriter
import datetime
import exp_fitting
import numpy as np

#Used with Timestamsp&BurstFlag Skecth

def _compute_error(residuals, x_residuals, error_metrics):
    assert error_metrics in ['KS', 'CM', None]
    error = None
    if error_metrics == 'KS':
        error = np.abs(residuals).max()*100
    elif error_metrics == 'CM':
        error = np.trapz(residuals**2, x=x_residuals)
    return error

def _exp_fit_generic(ph, fit_fun, tail_min_us=None, tail_min_p=0.1,
                     clk_p=12.5e-9, error_metrics=None):
  
    dph = np.diff(ph)
    if tail_min_us is None:
        tail_min = dph.max()*tail_min_p
    else:
        tail_min = tail_min_us*1e-6/clk_p

    res = fit_fun(dph, s_min=tail_min, calc_residuals=error_metrics is not None)
    Lambda, residuals, x_residuals, s_size = res

    error = _compute_error(residuals, x_residuals, error_metrics)
    Lambda /= clk_p
    return Lambda, error

def exp_fit(ph, tail_min_us=None, clk_p=12.5e-9, error_metrics=None):
 
    return _exp_fit_generic(ph, fit_fun=exp_fitting.expon_fit,
                            tail_min_us=tail_min_us, clk_p=clk_p,
                            error_metrics=error_metrics)

def time_extension():
    current_time = datetime.datetime.now()
    return '_' + str(current_time.year) + '_' + str(current_time.month) + \
        '_' + str(current_time.day) + '_' + str(current_time.hour) + \
            '_' + str(current_time.minute)
            
def hour_min_sec():
    current_time = datetime.datetime.now()
    return  str(current_time.hour) + ":" + str(current_time.minute) + \
        ":" + str(current_time.second)

    
def recieve_timestamps(mode):    
    workbook = xlsxwriter.Workbook("C:/Users/dmergy/Downloads/" + mode + time_extension() + ".xlsx")   
    worksheet = workbook.add_worksheet('Loop Version')
    

    worksheet.write('A1', 'time')
    worksheet.write('B1', 'val')
    worksheet.write('C1', 'NumberOfCycles [5ns]')
    worksheet.write('D1', 'BurstFlag')
    
    ActualTime = 0
    burst_flag_lst = []
    times_lst = []
    
    
    i=2
    while (1):
        line  = ser.readline().decode()
        line = line.rstrip()
        if (line == "(MCU) EndOfTransmission"):
            break
        splitted = line.split(',')
        dt_cycles  = int(splitted[0])
        burst_flag = int(splitted[1])
        
        ActualTime = ActualTime + dt_cycles * 5
        
        times_lst.append(ActualTime)
        burst_flag_lst.append(burst_flag)
    
        worksheet.write(f'A{i}', ActualTime)
        worksheet.write(f'B{i}', 1)
        worksheet.write(f'C{i}', dt_cycles)
        worksheet.write(f'D{i}', burst_flag)
        i += 1

        
    workbook.close()
   
    
    return times_lst, burst_flag_lst

def recieve_nk_and_coordinates():    
    workbook = xlsxwriter.Workbook("C:/Users/dmergy/Downloads/OrbitalTracking"
                           + time_extension() + ".xlsx")   
    worksheet = workbook.add_worksheet('Loop Version')

    worksheet.write('A1', 'Time [ms]')
    worksheet.write('B1', 'X')
    worksheet.write('C1', 'Y')
    worksheet.write('D1', 'nk')
    worksheet.write('E1', 'X_hat')
    worksheet.write('F1', 'Y_hat')

    start_time = 0
    i=2
    
    while (1):
        

        line  = ser.readline().decode()
        line = line.rstrip() 
        
        print(line)

    

        if (line == "(MCU) EndOfTransmissions"):
            break
      
        line_lst = line.split(',')
        

        Time  = float(line_lst[0])
        X = float(line_lst[1])
        Y     = float(line_lst[2])
        nk    = float(line_lst[3]) 
        X_hat = float(line_lst[4])
        Y_hat = float(line_lst[5])
        

        if (i==2):
            start_time = Time
        

        RealTime = float(float(Time)-float(start_time))
        worksheet.write(f'A{i}', RealTime)
        
        #worksheet.write(f'A{i}', Time)
        worksheet.write(f'B{i}', X)
        worksheet.write(f'C{i}', Y)
        worksheet.write(f'D{i}', nk)
        worksheet.write(f'E{i}', X_hat)
        worksheet.write(f'F{i}', Y_hat)
        i += 1

    workbook.close()


if __name__ == "__main__":
    get_str = "get T/N/F"
    set_str = "set T/N/F <value>"
    bsearch_str = "bsearch <value> msec/sec/min/photons"
    background_str = "background <value> msec/sec/min/photons"
    help_str = "list of commands accepted:" + '\n-' + get_str + '\n-' + \
        set_str + '\n-' + bsearch_str + '\n-' + background_str + "\n-exit"
    
    try:
         ser = serial.Serial('COM3', 9600)
         N = 8;
         F = 6;
         T = 10;
         while (1):
            command = input("Enter command:\n")
            splitted = command.split(' ')
        
            if command == "exit":
                ser.close()
                break
            
            elif command =="help":
                print(help_str)
        
            elif ((splitted[0] == "background") and (len(splitted) == 3)): 
                if  (splitted[2] in ['msec','sec','min','photons']) and (str.isdigit(splitted[1])):
                    
                    print("Background Estimation started at " + hour_min_sec())
                    cmd_str = "bsearch" + " " + splitted[1] + " "  + splitted[2] 
                    ser.write(cmd_str.encode())
                    
                    mcuresponse = ser.readline().decode().rstrip() ######
                    print(mcuresponse)
                    
                    
                    print("Collecting " + splitted[1] + " " + splitted[2]  + " of Data. Can take several minutes" )
                    print("...")
                    
                    
                    times_lst, burst_flag_lst = recieve_timestamps("background")
                    print("finished at " + hour_min_sec())
                    print("Results were saved in C:/Users/dmergy/Downloads/ ")
                    
                    
                    
                    rate = exp_fit(times_lst,5e-9) #in cps
                    print("Count Rate of Background is " + str(int(rate[0])))
                    updateT = input("Do you want to take this value for burstsearch ? (y/n) : ")
                    
                    if(updateT == "y"):
                        T_cycles = int((float(N)*1.0e9)/(5.0*float(F)*rate[0]))
                        new_cmd = "set T" + " " + str(T_cycles) 
                        ser.write(new_cmd.encode())
                        
                        mcuresponse = ser.readline().decode().rstrip() ######
                        
                        print(mcuresponse)
                        T = T_cycles
                        
                    #ese (updateT == "n"):
                    else:
                        print("T is currently" + " " + str(T * 5.0) +str(" ns"))
                        
                else:
                    print("Procedure cannot be executed. Try background <value> msec/sec/min/photons' ")
            
        
            elif ((splitted[0]  == "bsearch") and (len(splitted) == 3)) :
                if  (splitted[2] in ['msec','sec','min','photons']) and (str.isdigit(splitted[1])):
                    
                    print("Burst Search started at " + hour_min_sec())
                    ser.write(command.encode()) 
                    
                    mcuresponse = ser.readline().decode().rstrip() #############
                    print("(MCU) "+ str(mcuresponse))
                    
                    print("Collecting " + splitted[1] + " " + splitted[2] + " of Data. Can take several minutes" )
                    print("...")
                    times_lst, burst_flag_lst  = recieve_timestamps("bsearch")
                    print("finished at " + hour_min_sec())
                    print("Results were saved in C:/Users/dmergy/Downloads/ ")
                    
                    
                else:
                    print("Procedure cannot be executed. Try bsearch <value> msec/sec/min/photons' ")
        
            elif ((splitted[0] == "set") and (len(splitted) == 3)):
                if  (splitted[1] in ['N','T','F']) and (str.isdigit(splitted[2])):
                    if (splitted[1]) == 'N' : N  = splitted[2] 
                    if (splitted[1]) == 'T' : T  = splitted[2] 
                    if (splitted[1]) == 'F' : F  = splitted[2]  
                    ser.write(command.encode()) #Response MSG
                    mcuresponse = ser.readline().decode().rstrip()
                    print(mcuresponse)
                else:
                    print("Parameter cannot be set. Try 'set T/N/F <value>' ")
            
            
            elif ((splitted[0] == "get") and (len(splitted) == 2)):
            
            
                if (splitted[1] in ['N','T','F']): 
                    if (splitted[1]) == 'N' : print("N is set to: " + str(N) ) 
                    if (splitted[1]) == 'T' : print("T is set to: " + str(T*5) + str(" ns")) 
                    if (splitted[1]) == 'F' : print("F is set to: " + str(F) ) 
                else:
                    print("Parameter not found. Try 'get T/N/F' ")  
                
            elif ((splitted[0] == "start_finding") and (len(splitted) == 1)):
                ser.write(command.encode()) #Response MSG
                mcuresponse = ser.readline().decode().rstrip()
                print(mcuresponse)
                print("Burst Finding started at " + hour_min_sec())

                #SWITCH TO NK MODE
                print("...")
                found_str = "(MCU) A Burst has been detected! , scanning the neighborhood..."

                
                while (1):
                    line  = ser.readline().decode()
                    line = line.rstrip() 
                    
                    if (line == found_str):
                        print("A Burst has been detected!")
                        print("begin orbital tracking")
                        print("...")
                        break
                
                
                recieve_nk_and_coordinates()
                print("finished at " + hour_min_sec())
                print("Results were saved in C:/Users/dmergy/Downloads/ ")

    
            else:
                print("Invalid command. For help enter 'help'")
                
                
    except :
         ser.close()
         
