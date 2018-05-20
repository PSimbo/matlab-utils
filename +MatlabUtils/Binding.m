classdef Binding < handle
    properties (Dependent)
        Converter;
        Mode;
        Source;
        Target;
    end
    
    properties (Access = private, Hidden = true)
        converter;
        mode = Binding.BindingMode.TwoWay;
        source;
        sourceListener;
        sourceProperty;
        target;
        targetListener;
        targetProperty;
    end
    
    %% CONSTRUCTOR
    methods
        function this = Binding(source, sourceProp, target, targetProp, varargin)
            % Check that the chosen source property is suitable.
            sourceMeta = meta.class.fromName(class(source));
            
            propFound = false;
            for x = 1:numel(sourceMeta.PropertyList)
                if strcmp(sourceMeta.PropertyList(x).Name, sourceProp)
                    if ~sourceMeta.PropertyList(x).SetObservable
                        error('Property "%s" of source class "%s" is not marked as observable.', sourceProp, ...
                            class(source));
                    end
                    
                    propFound = true;
                    break;
                end
            end
            
            if ~propFound
                error('There is no property "%s" for source class "%s".', sourceProp, class(source));
            end
            
            this.source = source;
            this.sourceProperty = sourceProp;
            
            % Check that the chosen target property is suitable.
            targetMeta = meta.class.fromName(class(target));
            
            propFound = false;
            for x = 1:numel(targetMeta.PropertyList)
                if strcmp(targetMeta.PropertyList(x).Name, targetProp)
                    if ~targetMeta.PropertyList(x).SetObservable
                        error('Property "%s" of target class "%s" is not marked as observable.', targetProp, ...
                            class(target));
                    end
                    
                    propFound = true;
                    break;
                end
            end
            
            if ~propFound
                error('There is no property "%s" for target class "%s".', targetProp, class(target));
            end
            
            for x = 1:2:numel(varargin)
                switch varargin{x}
                    case 'Converter'
                        this.Converter = varargin{x + 1};
                end
            end
            
            % Set the target to match the source.
            if ~isempty(this.converter)
                target.(targetProp) = this.converter(source.(sourceProp));
            else
                target.(targetProp) = source.(sourceProp);
            end
            
            this.target = target;
            this.targetProperty = targetProp;
            
            for x = 1:2:numel(varargin)
                switch varargin{x}
                    case 'Mode'
                        this.mode = varargin{x + 1};
                end
            end
            
            this.updateListeners();
        end
    end
    
    %% GETTERS & SETTERS
    methods
        function value = get.Converter(this)
            value = this.converter;
        end
        
        function value = get.Mode(this)
            value = this.mode;
        end
        
        function value = get.Source(this)
            value = this.source;
        end
        
        function value = get.Target(this)
            value = this.target;
        end
        
        function set.Converter(this, value)
            if ~isa(value, 'function_handle') || ~isscalar(value)
                error('Must be a scalar function handle.');
            end
            
            this.converter = value;
        end
        
        function set.Mode(this, value)
            if ~isa(value, 'Binding.BindingMode') || ~isscalar(value)
                error('Must be a scalar value of type Binding.BindingMode.');
            end
            
            this.mode = value;
            this.updateListeners();
        end
    end
    
    %% PRIVATE METHODS
    methods
        function updateListeners(this)
            if this.mode == Binding.BindingMode.OneWay || this.mode == Binding.BindingMode.TwoWay
                this.sourceListener = addlistener(this.source, this.sourceProperty, 'PostSet', @(h, e) this.bind(h));
            else
                delete(this.sourceListener);
                this.sourceListener = [];
            end
            
            if this.mode == Binding.BindingMode.OneWayToSource || this.mode == Binding.BindingMode.TwoWay
                this.targetListener = addlistener(this.target, this.targetProperty, 'PostSet', @(h, e) this.bind(h));
            else
                delete(this.targetListener);
                this.targetListener = [];
            end
        end
        
        function bind(this, h)
            persistent loopCheck;  % Guard against cyclic behaviour.
            
            if isa(this.source, h.DefiningClass.Name)
                % The source's listener has triggered. Check the binding mode for whether the target should be updated.
                if this.mode == Binding.BindingMode.OneTime || this.mode == Binding.BindingMode.OneWay || ...
                        this.mode == Binding.BindingMode.TwoWay
                    if isempty(loopCheck)
                        loopCheck = 1;  %#ok<NASGU>
                        if ~isempty(this.converter)
                            this.target.(this.targetProperty) = this.converter(this.source.(this.sourceProperty));
                        else
                            this.target.(this.targetProperty) = this.source.(this.sourceProperty);
                        end
                    end
                end
            elseif isa(this.target, h.DefiningClass.Name)
                % The target's listener has triggered. Check the binding mode for whether the source should be updated.
                if this.mode == Binding.BindingMode.OneWayToSource || this.mode == Binding.BindingMode.TwoWay
                    if isempty(loopCheck)
                        loopCheck = 1;  %#ok<NASGU>
                        if ~isempty(this.converter)
                            this.source.(this.sourceProperty) = this.converter(this.target.(this.targetProperty));
                        else
                            this.source.(this.sourceProperty) = this.target.(this.targetProperty);
                        end
                    end
                end
            end
            
            loopCheck = [];
        end
    end
end