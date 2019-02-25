#!/usr/bin/env bash
#DataTime: 2019-2-23
#Author: xueyujie
#Descprition: a simple mini top
#version="1.0"

#init var
sleep_time="1"
sort_num="6"

#init color fornt
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
normal=$(tput sgr0)

#trap ctrl_c singal
function finish() {
  clear
  stty echo
  stty -igncr
  echo "bye bye!"
  tput cnorm
  exit 0
  reset
}

trap finish SIGINT

function flush_data() 
{
pids=($(ls -d /proc/* | grep -o '[0-9]*'))
pidsTotal=${#pids[@]}

for (( i=0; i<${pidsTotal}; i++));
do
  [[ -f /proc/${pids[i]}/stat ]] && usn1[i]=$(awk '{print $14+$15}' /proc/${pids[i]}/stat )
done
declare -i timecpu1=`sed 's/\.//' <<< $(cut -f1 -d " " /proc/uptime)`
for (( i=0; i<${pidsTotal}; i++));
do
  [[ -f /proc/${pids[i]}/stat ]] && usn2[i]=$(awk '{print $14+$15}' /proc/${pids[i]}/stat )
done
for (( i=0; i<${pidsTotal}; i++ ));
do
  timeinit=${usn1[i]}
  timelast=${usn2[i]}
  difftime[i]=$((timelast-timeinit))
done
declare -i timecpu2=$(sed 's/\.//' <<< $(cut -f1 -d " " /proc/uptime))
timecpulast=$(($timecpu2-$timecpu1))
for (( i=0; i<${pidsTotal}; i++ ));
do
  difftimevalue=${difftime[i]}
  usagecpu[i]=$(bc <<< "scale=2;($difftimevalue/$timecpulast)*100")
  #usagecpu[i]=$(awk 'BEGIN { printf "%.2f\n", ($difaux/$tiempoCPU)*100 }')
done

usoCPUTotal=`cat <(grep 'cpu ' /proc/stat) <(sleep 1 && grep 'cpu ' /proc/stat) | awk -v RS="" '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}'`
printf "minitop -,"
# pidsTotal=${#pids[@]}
printf "%13s" "${blue}process: ${normal}$pidsTotal,"

system_uptime=$(awk '{printf("%d days %02d:%02d:%02d\n",($1/60/60/24),($1/60/60%24),($1/60%60),($1%60))}' /proc/uptime)
printf "%20s" "${blue}uptime: ${yellow}${system_uptime} ${normal},"

login_user_numbers=$(users | wc -w)
printf "%30s" "${blue}login_user_num: ${yellow}${login_user_numbers}${normal},"

core_num=$(awk -F: '/cpu cores/{ num+=$2 } END{ print  num }' /proc/cpuinfo)
printf "%30s" "${blue}cpu_core_num: ${yellow}${core_num}${normal},"

printf "%10s" "${blue}usecpu: ${normal}$usoCPUTotal,"

memTotal=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
printf "%30s" "${blue}memtotal: ${yellow}$memTotal ${normal}KB,"

memFree=$(awk '/MemFree/ {print $2}' /proc/meminfo)
printf "%30s" "${blue}memfree: ${yellow}$memFree ${normal}KB,"

memUSE=$((memTotal-memFree));
printf "%20s" "${blue}memuse: ${yellow}$memUSE ${normal}KB,"

awk '{ printf "load average: %s, %s ,%-10s\n", $1, $2, $3 }' /proc/loadavg 
cpu_num=($(awk '/cpu*/{printf "%s ", NR-1}' /proc/stat))
unset 'cpu_num[${#cpu_num[@]}-1]'
cpu_arry=($(for i in "${cpu_num[@]}";do { cat <(grep cpu${i} /proc/stat) <(sleep 1 && grep cpu${i} /proc/stat) | awk -v RS="" '{print ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5) "%"}' & };done;wait ))

echo -e '\n'
for (( i=0; i<${pidsTotal}; i++ ));
do
   if [[  -f /proc/${pids[i]}/status ]]; then
    pidProceso=${pids[i]}
    pid[i]=$pidProceso
    usid=$(awk '/Uid:/ {print $2}' /proc/${pids[i]}/status)
    userid[i]=$usid
    username=$(getent passwd "${userid[i]}" | cut -d: -f1)
    user[i]=$username
  fi
  if [ -f /proc/${pids[i]}/stat ]; then 
    prior=`awk '{t=$18;print t}' /proc/${pids[i]}/stat`
    prioridad[i]=$prior
    memoriaVirtual=`awk '{print $23}' /proc/${pids[i]}/stat`
    virt[i]=$(($memoriaVirtual/1000))
    state=`awk '{print $3}' /proc/${pids[i]}/stat`
    s[i]=${state}
    mempr=`awk '{print $24}' /proc/${pids[i]}/stat`
    memPag[i]=$(($mempr * 4))
    memaux=${memPag[i]}
    memaux2=$(bc <<< "scale=2;$memaux*100/$memTotal");
    mem[i]="$memaux2"
    #echo ${mem[i]} dasdadasd
    tiem=`awk '{t=$14+$15;print t}' /proc/${pids[i]}/stat`
    tiempo[i]=$((tiem))
    tmm=$((${tiempo[i]}/100));
    tss=$((${tiempo[i]}-(tmm*100)));
    thh=$(($tmm/60));
    tmmi=$tmm
    tssi=$tss
    if (( $tmm > 60 )); then
      tmmi=$(($tmm%60))
    fi
    time[i]=$(printf "%d:%d.%d\n" $(($thh)) $(($tmmi)) $(($tssi)))
    #echo ${time[i]}
    programaInvocado=`awk '{t=$2;print t}' /proc/${pids[i]}/stat`
    command[i]=$programaInvocado
    fi
    usagecpuaux=$(bc <<< "scale=2;${usagecpu[i]}");
    cpu[i]=${usagecpuaux} 
done 

printf "\033[41;36m%-6s\033[0m \033[41;36m%-9s\033[0m \033[41;36m%-4s\033[0m \033[41;36m%-8s\033[0m \033[41;36m%-4s\033[0m \033[41;36m%-8s\033[0m \033[41;36m%-6s\033[0m \033[41;36m%-11s\033[0m \033[41;36m%-30s\033[0m\n" PID USER PR VIRT S %CPU %MEM TIME+ COMMAND
printf '=%.0s' $(seq 1 $(tput cols))
echo -e " \e[0m"

V=($(for (( i=0; i<${pidsTotal}; i++ )); 
        do  echo "${pid[$i]}" "$(a=${user[$i]};[[ ${#a} -gt 7 ]] &&  echo ${a:0:7}"+" || echo ${user[$i]})" "${prioridad[$i]}" "${virt[$i]}" "${s[$i]}" "${cpu[$i]}" "${mem[$i]}" "${time[$i]}" "${command[$i]}" 
        done | sort -k${sort_num} -nr | head -15))

LANG=C printf "%-6s %-10s %-4s %-8s %-4s %-8s %-6.2f %-15s %-20s\n" ${V[@]}
printf '=%.0s' $(seq 1 $(tput cols))

cpu_utl=${usoCPUTotal%%%*}
usage=$(echo | awk "{printf int(${cpu_utl})/6}")
arr+=("${usage}")
arr_length=${#arr[*]}
tput cup 7 90
clo=90
a=$(printf "%-0.s@" $(seq 1 ${usage}))
line='                '
#line='@@@@@@@@@@@@@@@@@'
lines=8

printf "cpu *: [\e[1;31m%-s\e[m\e[1;34m%-s\e[m\e[1;35m%-s\e[m\e[1;33m%-s\e[m] \e[1;32m%-15s\e[m" "${a:0:3}" "${a:3:5}" "${a:8}" "${line:${#a}}" "@$usoCPUTotal"
#[[ $usage -le 3 ]] && printf "cpu *:[\e[1;34m%-s\e[m\e[1;33m%-s\e[m] \e[1;32m%-15s\e[m" "${a:0:2}" "${line:${#a}}" "@$usoCPUTotal" || printf "cpu *:[\e[1;34m%-s\e[m\e[1;31m%-s\e[m\e[1;33m%-s\e[m] \e[1;32m%-15s\e[m" "${a:0:3}" "${a:4:9}" "${line:${#a}}" "@$usoCPUTotal"
for j in "${cpu_num[@]}";
do
  tput cup $lines 90
  b=${cpu_arry[$j]}
  cpu_utl=${b%%%*}
  usage=$(echo | awk "{printf int(${cpu_utl})/6}")
  b=$(printf "%-0.s@" $(seq 1 ${usage}))
  ((lines++))
#  [[ $usage -le 3 ]] && printf "cpu $j:[\e[1;34m%-s\e[m\e[1;33m%-s\e[m] \e[1;32m%-15s\e[m" "${b:0:3}" "${line:${#b}}" "@$(echo ${cpu_arry[$j]})" || printf "cpu $j:[\e[1;34m%-s\e[m\e[1;31m%-s\e[m\e[1;33m%-s\e[m] \e[1;32m%-15s\e[m" "${b:0:2}" "${b:3}" "${line:${#b}}" "@$(echo ${cpu_arry[$j]})" 
printf "cpu $j: [\e[1;31m%-s\e[m\e[1;34m%-s\e[m\e[1;35m%-s\e[m\e[1;33m%-s\e[m] \e[1;32m%-15s\e[m" "${b:0:3}" "${b:3:5}" "${b:8}" "${line:${#b}}" "@$(echo ${cpu_arry[$j]})" 
done
tput cup 18 $(($(tput cols)-55));date
}

interval() {
    tput init
    tput clear
    stty igncr
  while :;
  do
    tput sc
    tput civis 
    read -t 0.01 -s -rN 1 key
      case "$key" in
        [qQ])sort_num="7";#break;#flush_data;sleep ${sleep_time};tput rc;
        ;;
        [wW])sort_num="6";#break;
        ;;
      esac
    stty -echo    
    flush_data
    stty echo
    sleep ${sleep_time}
    tput rc
done
}

while getopts "d:vh" opt; do
  case $opt in
    d ) sleep_time="$OPTARG";
       interval;;
    v ) printf "%19s\n" "minitop version 1.0";exit 0;;
    h ) printf "%10s\n" "-d delay scondes.example minitop.sh -d1/-d 1";
        printf "%10s\n" "-v display minitop version.example minitop.sh -h";
        printf "%10s\n" "-h display minitop help.minitop.sh -h";
        exit 0;;
  esac
done

interval
