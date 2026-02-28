import numpy as np
import matplotlib.pyplot as plt
from tqdm import tqdm
import os
#got the log file as a command line argument


#executre a vivado script to run the project and collect the log file, then parse the log file to extract the adc values and plot them
tcl_script = "E:/Libraries/Documents/LAB_VNA/EVAL_BOARDS/artix_eval/Rev_A/FirmwareSource/scripts/ADC_TEST_SCRIPTS/dump_adc_core_xsdb.tcl"
os.system(f"vivado -mode batch -source {tcl_script}")
print("Finished running Vivado script, now parsing log file...")
#cleanup
# os.remove(".Xil")
os.remove("vivado.log")
os.remove("vivado.jou")


try:
    import sys
    Log_File = sys.argv[1]
except IndexError:
    print("Usage: python parse_adc_dump.py <log_file>")
    Fall_back_file = "E:/Libraries/Documents/LAB_VNA/EVAL_BOARDS/artix_eval/Rev_A/FirmwareSource/scripts/ADC_TEST_SCRIPTS/dump_adc_core.log"
    print(f"No log file provided, using fall back file: {Fall_back_file}")
    Log_File = Fall_back_file


def read_memory_line(line):
    line = line.strip().split()
    address = line[0]
    data = "".join(line[1:])
    return address, data

total_data = ""
for line in tqdm(open(Log_File, "r")):
    try:
        address, data = read_memory_line(line)
        total_data += data
        # print(f"Address: {address}, Data: {data}")
    except IndexError:
        pass

def convert3x32_to_4x24(data_str):
    # Convert the 3x32-bit data to 4x24-bit data
    temp = int(data_str, 16)  # Convert the hex string to an integer 
    out = [0] * 4
    out[0] = ((temp >> 72) & 0xFFF000) >> 12  # Extract the first 24 bits and shift to get the 12-bit value
    out[1] = ((temp >> 48) & 0xFFF000) >> 12
    out[2] = ((temp >> 24) & 0xFFF000) >> 12
    out[3] = ((temp >> 0) & 0xFFF000) >> 12

    # print(f"dOut: {[f'{x:03X}' for x in out]}")
    return out

CHARACTERS_PER_BYTE = 2
BITS_PER_CHARACTER = 8/CHARACTERS_PER_BYTE
sync_offset = 1
values = []

for i in tqdm(range(0, len(total_data), int(3* 32/BITS_PER_CHARACTER))):
    start_charcater = i + sync_offset
    end_character = i + 3* int(32/BITS_PER_CHARACTER) + sync_offset * int(32/BITS_PER_CHARACTER)
    # print(f"Start: {start_charcater}, End: {end_character}")
    if end_character > len(total_data):
        # print("Reached end of data")
        break
    string_chunk = total_data[start_charcater:end_character]
    # print(f"Chunk: {string_chunk}")
    # print(string_chunk)
    points = convert3x32_to_4x24(string_chunk)
    values.extend(points)

values = np.array([value if value < 0x800 else value - 0x1000 for value in values])
SAMPLE_RATE = 64e6 # 64 MSPS
ADC_Bits = 12

print("Number of Samples: ", len(values))
Beats = len(values) /4 * 3
print("Beats: ", Beats)


# exit()

#test data

test_time = np.linspace(0, len(values)/SAMPLE_RATE, len(values)) # time vector for the test signal
test_5MHz_signal = 2047 * np.sin(2 * np.pi * 5e6 * test_time) # 5 MHz sine wave with 0.5 V amplitude
 
values = values - np.mean(values) #remove DC offset
#apply a Hanning window to the values to reduce spectral leakage
window = np.hanning(len(values))
# window = np.ones(len(values))
windowed_values = values * window
fft_values = np.fft.fft(windowed_values) #normalise by signal length

dBFS_Correction = 20 * np.log10(2**(ADC_Bits-1) - 1) + 20*np.log10(np.sum(window)) - 20 * np.log10(np.sqrt(2)) - 3 #correction factor to convert to dBFS ++


#calculate the frequencies corresponding to the FFT values
frequencies = np.fft.fftfreq(len(values), 1/SAMPLE_RATE) 
fft_values = 20 * np.log10(np.abs(fft_values)) - dBFS_Correction
# plt.subplot(2, 1, 1)
# plt.plot(test_time*1e6, values)
# plt.title("ADC Values Over Time")
# plt.xlabel("Time (microseconds)")
# plt.ylabel("ADC Value (codes)")
# plt.subplot(2, 1, 2)
plt.plot(frequencies[:len(frequencies)//2]/1e6, fft_values[:len(fft_values)//2])
plt.title("FFT of ADC Values")
plt.xlabel("Frequency (MHz)")
plt.ylabel("Magnitude (dBFS)")
plt.show()





#TODOS

#Add delay in mcu software to allow the adc to begin the transfer before triggering the dma
#automate running the project in a python script and collecting the log file
#connect to the signal analyser to control the test stimulus


#sample 0 - 10 Vpp
#sample 0 - 60 MHz signal

#then do IM3 measurements