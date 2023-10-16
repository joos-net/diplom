[all]
%{ for host, host_data in hosts ~}
$${host_data.ansible_host}
%{ endfor ~}

[all:children]
%{ for group, data in groups ~}
${group}
%{ endfor ~}

%{ for group, group_data in groups ~}
[${group}]
%{ for host, host_data in group_data.hosts ~}
${host_data.ansible_host}
%{ endfor ~}
%{ endfor ~}