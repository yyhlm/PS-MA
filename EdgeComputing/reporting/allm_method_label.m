function label = allm_method_label(key)

switch key
    case 'psma'
        label = 'PS-MA';
    case 'hlinucb'
        label = 'hLinUCB';
    case 'tsicf'
        label = 'TS-ICF';
    case 'gcl2c'
        label = 'GCL-PSMC';
    case 'glmucb'
        label = 'GLM-UCB';
    otherwise
        error('allm:UnknownMethod', 'Unknown method key: %s', key);
end
end