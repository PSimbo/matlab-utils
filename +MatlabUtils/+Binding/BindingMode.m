classdef BindingMode < uint8
    enumeration
        OneTime (2);  % One-time version of "OneWay"
        OneWay (1);  % Source to target only
        OneWayToSource (3);  % Target to source only
        TwoWay (0);
    end
end