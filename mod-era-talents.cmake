# mod-era-talents — era-gated Vanilla/TBC talent trees for mod-individual-progression characters.
if(TARGET modules)
  target_include_directories(modules PRIVATE ${CMAKE_CURRENT_LIST_DIR}/src)

  # mod-individual-progression is REQUIRED (eras come from IP). EraTalentIP.cpp is the ONLY
  # translation unit that includes its header — never include IP and playerbots in the same TU
  # (both define a GENERAL enumerator).
  set(_IP_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-individual-progression/src")
  if(NOT EXISTS "${_IP_SRC}/IndividualProgression.h")
    message(FATAL_ERROR "[mod-era-talents] mod-individual-progression not found at ${_IP_SRC}.\n"
      "  git clone https://github.com/ZhengPeiRu21/mod-individual-progression.git modules/mod-individual-progression")
  endif()
  target_include_directories(modules PRIVATE ${_IP_SRC})

  # mod-playerbots is OPTIONAL. The playerbots fork of the core already defines MOD_PLAYERBOTS on
  # game-interface when the module is present; define it here too so the module never depends on
  # that fork detail. Without it every bot code path compiles out (see src/EraTalentBots.cpp).
  set(_PB_SRC "${CMAKE_CURRENT_LIST_DIR}/../mod-playerbots/src")
  if(EXISTS "${_PB_SRC}/Script/Playerbots.h")
    target_include_directories(modules PRIVATE ${_PB_SRC} ${_PB_SRC}/Script ${_PB_SRC}/Bot ${_PB_SRC}/Bot/Factory ${_PB_SRC}/Ai/Base)
    target_compile_definitions(modules PRIVATE MOD_PLAYERBOTS)
    message(STATUS "[mod-era-talents] mod-playerbots found — bot era talents compiled in")
  else()
    message(STATUS "[mod-era-talents] mod-playerbots not found — bot support compiled out (players only)")
  endif()
endif()
