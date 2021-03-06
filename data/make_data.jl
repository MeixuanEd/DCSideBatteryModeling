using PowerSystems
using NLsolve

omib_file_dir = joinpath(pwd(), "data/OMIB.raw")
# Data in raw file only contains partial network information. Checks are disabled since we know that the data can't pass all checks.
omib_sys =
    System(PowerModelsData(omib_file_dir), time_series_in_memory = true, runchecks = false)
slack_bus = get_components_by_name(Component, omib_sys, "Slack Bus")[1]
battery = GenericBattery(
    base_power = 250.0,
    name = "Battery",
    prime_mover = PrimeMovers.BA,
    available = true,
    bus = slack_bus,
    initial_energy = 5.0,
    state_of_charge_limits = (min = 5.0, max = 100.0),
    rating = 70.0, #Value in per_unit of the system
    active_power = 10.0,
    input_active_power_limits = (min = 0.0, max = 50.0),
    output_active_power_limits = (min = 0.0, max = 50.0),
    reactive_power = 0.0,
    reactive_power_limits = (min = -50.0, max = 50.0),
    efficiency = (in = 0.80, out = 0.90),
)
add_component!(omib_sys, battery)
res = solve_powerflow!(omib_sys)

###### Converter Data ######
converter() = AverageConverter(rated_voltage = 690.0, rated_current = 2.75)
###### DC Source Data ######
dc_source() = FixedDCSource(voltage = 600.0) #Not in the original data, guessed.

###### Filter Data ######
filter() = LCLFilter(lf = 0.08, rf = 0.003, cf = 0.074, lg = 0.2, rg = 0.01)

###### PLL Data ######
pll() = KauraPLL(
    ω_lp = 500.0, #Cut-off frequency for LowPass filter of PLL filter.
    kp_pll = 0.084,  #PLL proportional gain
    ki_pll = 4.69,   #PLL integral gain
)

###### Outer Control ######
function outer_control()
    function virtual_inertia()
        return VirtualInertia(Ta = 2.0, kd = 400.0, kω = 20.0, P_ref = 1.0)
    end
    function reactive_droop()
        return ReactivePowerDroop(kq = 0.2, ωf = 1000.0)
    end
    return OuterControl(virtual_inertia(), reactive_droop())
end

######## Inner Control ######
inner_control() = CurrentControl(
    kpv = 0.59,     #Voltage controller proportional gain
    kiv = 736.0,    #Voltage controller integral gain
    kffv = 0.0,     #Binary variable enabling the voltage feed-forward in output of current controllers
    rv = 0.0,       #Virtual resistance in pu
    lv = 0.2,       #Virtual inductance in pu
    kpc = 1.27,     #Current controller proportional gain
    kic = 14.3,     #Current controller integral gain
    kffi = 0.0,     #Binary variable enabling the current feed-forward in output of current controllers
    ωad = 50.0,     #Active damping low pass filter cut-off frequency
    kad = 0.2,
)

inverter = DynamicInverter(
    static_injector = battery,
    ω_ref = 1.0,
    converter = converter(),
    outer_control = outer_control(),
    inner_control = inner_control(),
    dc_source = dc_source(),
    freq_estimator = pll(),
    filter = filter(),
)

add_component!(omib_sys, inverter)
to_json(omib_sys, joinpath(pwd(), "data/OMIB_inverterDCside.json"); force = true)
