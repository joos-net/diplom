%{ for group, group_data in groups ~}
%{ for host, host_data in group_data.hosts ~}
%{if group == "bastion"}
Host bastion
  User joos
  Hostname ${host_data.network_interface.0.nat_ip_address}
  StrictHostKeyChecking no
%{endif}
%{ endfor ~}
%{ endfor ~}

%{ for group, group_data in groups ~}
%{ for host, host_data in group_data.hosts ~}
Host ${host_data.network_interface.0.ip_address}
  ProxyJump bastion
  StrictHostKeyChecking no

%{ endfor ~}
%{ endfor ~}