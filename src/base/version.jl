const VERSION_NUMBER = try
    convert(VersionNumber, "v0.18.0-DEV")
catch e
    warn("While creating PredictMD.VERSION_NUMBER, ignoring error $(e)")
    VersionNumber(0)
end

"""
    VERSION_NUMBER
"""
VERSION_NUMBER
