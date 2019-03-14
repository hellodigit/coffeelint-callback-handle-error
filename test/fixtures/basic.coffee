class Snake
  move: (asdf)->
    if err
      throw err
    return
  d:
    bad: (err)-> # HIT
      return
    good: (err)->
      if err
        console.log err
      return

  run: (err, @speed, callback)->
    done err

bad 777, (err)-> # HIT
  return

good 777, (err)->
  if err
    console.log err
  return

abc = 1
bad = 666

good 777, (err)->
  if abc or err
    console.log err
  return

good1 777, (err, callback)->
  if err
    return

  good2 777, (err)->
    callback err
    return
  return

bad1 777, (overwritten_err, callback)-> # HIT
  if bad
    return

  good2 777, (overwritten_err)->
    callback overwritten_err
    return
  return

good 777, (stuff, ..., err, ttt)->
  callback err
  return

badExpansion 777, (stuff, ..., err, ttt)-> # HIT
  callback ttt
  return

bad2 777, (err, callback)-> # HIT
  bad = 5
  callback(err)

bad3 777, (err, callback)-> # HIT
  doSomething()
  callback(err)

badObjDestructuring thing, (err, {A, B, C})-> # HIT
  callback err

okObjDestructuringWithDefault thing, (err, {A, B, C} = {})->
  callback err

badObjDestructuringWithWrongTypeDefault thing, (err, {A, B, C} = [])-> # HIT
  callback err

badArrDestructuring thing, (err, [A, B, C])-> # HIT
  callback err

okArrDestructuringWithDefault thing, (err, [A, B, C] = [])->
  callback err

badArrDestructuringWithWrongTypeDefault thing, (err, [A, B, C] = {})-> # HIT
  callback err
