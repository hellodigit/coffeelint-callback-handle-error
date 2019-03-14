getNodeType = (node) ->
  return node.constructor.name

module.exports = class CallbackHandleError
  rule:
    name: 'callback_handle_error'
    level: 'error'
    message: 'Error in callback not handled'
    description: '''
      Finds instances of error objects passed through a callback not being handled
    '''

    # param name config
    patterns: ["^err(or)?", "[Ee]rr(or)?$"]

  lintAST: (node, @astApi) ->
    patterns = @astApi.config.patterns ? @rule.patterns
    @errorVariablePatterns = (new RegExp(pattern) for pattern in patterns)
    @lintNode node
    return

  lintNode: (node) ->
    node_type = getNodeType(node)

    switch node_type
      when 'Code'
        for param in node.params
          var_name = param.name?.value
          for pattern in @errorVariablePatterns
            if pattern.test(var_name) && !@handlesError(node, var_name)
              @throwError node, "Error object '#{var_name}' in callback not handled"
              break

    node.eachChild (child)=>
      @lintNode child
      return
    return

  handlesError: (code_node, var_name)->
    obj_idents_pending = []
    obj_idents = []
    non_usages = []
    found_usage = false

    code_node.traverseChildren true, (child)->
      node_type = getNodeType child

      switch node_type
        when 'If'
          found_non_usage = non_usages.length > 0
          # check for if they use the error in an if
          child.condition.traverseChildren false, (inner_child)->
            inner_type = getNodeType inner_child
            switch inner_type
              # HACK: Handles change of token naming in CoffeeScript 1.11.0
              when 'Literal', 'IdentifierLiteral'
                if inner_child.value is var_name
                  if not found_non_usage
                    found_usage = true
                    return false
            return

        when 'Call'
          # passing the error to another call is considered using it
          function_name = child.variable?.base?.value
          found_non_usage = non_usages.some (a) -> a isnt function_name

          for arg in child.args
            arg.traverseChildren false, (inner_child)->
              inner_type = getNodeType inner_child
              switch inner_type
                # HACK: Handles change of token naming in CoffeeScript 1.11.0
                when 'Literal', 'IdentifierLiteral'
                  if inner_child.value is var_name
                    if not found_non_usage
                      found_usage = true
                      return false
              return
          return

        when 'Code'
          # stop going down the chain when the var gets overwritten with another param
          for param in child.params
            inner_child_type = getNodeType param
            if inner_child_type is 'Param'
              if param.name.value is var_name
                return false

        when 'Value'
          # child_type = getNodeType child
          if not (child.base?.value in [undefined, var_name, 'this'].concat(obj_idents))
            non_usages.push child.base?.value
            return true

        # Allow object/array param destructuring with default.
        # Default is important because without it, a property can be accessed
        # on undefined, causing a JS runtime error.
        #
        # doSomething 777, (err, {A, B, C} = {}) -> return done err if err
        # doSomething 777, (err, [A, B, C] = []) -> return done err if err
        when 'Param'
          nameType = getNodeType child.name
          if nameType in ['Arr', 'Obj']
            obj_idents_pending = []
            for obj in child.name.objects
              inner_child_type = getNodeType obj
              if inner_child_type is 'Value'
                obj_idents_pending.push obj.base.value

            if child.value?.base
              valueType = getNodeType child.value.base
              if valueType is nameType
                unless child.value.base.objects.length
                  obj_idents = obj_idents.concat obj_idents_pending
                  obj_idents_pending = []

      # if we already found a usage, break out of the traverse
      if found_usage
        return false
      return

    return found_usage

  throwError: (node, message) ->
    err = @astApi.createError
      lineNumber: node.locationData.first_line + 1
      message: message
    @errors.push err
    return
