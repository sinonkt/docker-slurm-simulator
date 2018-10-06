import os

def slurm_conf_parser(slurm_conf_loc):
    """very simple parser to get some parameters from slurm.conf"""
    if not os.path.isfile(slurm_conf_loc):
        raise Exception("Can not find slurm.conf at "+slurm_conf_loc)

    params = {}
    with open(slurm_conf_loc, 'rt') as fin:
        lines = fin.readlines()
        for l in lines:
            l = l.strip()
            if len(l) == 0:
                continue
            if l[0] == '#':
                continue
            comment = l.find('#')
            if comment >= 0:
                l = l[:comment]
                l = l.strip()

            setsign = l.find('=')
            if setsign >= 0:
                name = l[:setsign].strip()
                if len(l) > setsign+1:
                    value = l[setsign+1:].strip()
                else:
                    value = "None"
                params[name.lower()] = value

    return params


def print_updated_config_file(filename, vars_new_val):
    def update_line(l):
        l2 = l.strip()
        l_new = l
        if len(l2) != 0 and l2[0] != '#':
            comment = l2.find('#')
            if comment >= 0:
                l2 = l2[:comment]
                l2 = l2.strip()

            setsign = l2.find('=')
            if setsign >= 0:
                name = l2[:setsign].strip()
                if len(l2) > setsign+1:
                    value = l2[setsign+1:].strip()
                else:
                    value = "None"
                if name.lower() in vars_new_val:
                    l_new = name+" = "+str(vars_new_val[name.lower()])+"\n"
        return l_new
    for k in list(vars_new_val.keys()):
        vars_new_val[k.lower()] = vars_new_val[k]
    if not os.path.isfile(filename):
        raise Exception("Can not find "+filename)
    with open(filename, 'rt') as fin:
        lines = fin.readlines()
        for l in lines:
            print(update_line(l))
