mod completions;
mod device;
mod pair;
mod scan;

use clap::{ArgAction, ArgMatches, Command, arg, value_parser};
use macaddr::MacAddr6;
use openscq30_lib::DeviceModel;

pub fn build() -> Command {
    let mac_address_arg = arg!(-a --"mac-address" <MAC_ADDRESS> "Device's MAC address (e.g., AA:BB:CC:DD:EE:FF)")
        .value_parser(value_parser!(MacAddr6));
    let device_model_arg = arg!(-m --model <MODEL> "Device model (e.g., SoundcoreA3040)")
        .required(true)
        .value_parser(value_parser!(DeviceModel));
    let json_arg = arg!(-j --json "Output as JSON for machine parsing");

    Command::new(env!("CARGO_BIN_NAME"))
        .version(env!("CARGO_PKG_VERSION"))
        .about("Control Soundcore headphones and earbuds from the command line")
        .after_help("For more information, visit: https://github.com/Oppzippy/OpenSCQ30")
        .arg(
            arg!(--"debug-errors" "Display additional error information for debugging")
                .global(true)
        )
        .arg(
            arg!(-v --verbose ... "Increase logging verbosity (-v warn, -vv info, -vvv debug, -vvvv trace)")
                .global(true)
                .action(ArgAction::Count)
        )
        .arg(
            arg!(-c --config <PATH> "Path to configuration file")
                .global(true)
        )
        .subcommand_required(true)
        .subcommand(
            Command::new("paired-devices")
                .about("Manage paired Soundcore devices")
                .alias("pd")
                .subcommand_required(true)
                .after_help(
                    "Examples:\n  \
                    openscq30 pd add -a AA:BB:CC:DD:EE:FF -m SoundcoreA3040\n  \
                    openscq30 pd list\n  \
                    openscq30 pd remove -a AA:BB:CC:DD:EE:FF"
                )
                .subcommand(
                    Command::new("add")
                        .about("Add a new paired device")
                        .arg(mac_address_arg.clone().required(true))
                        .arg(device_model_arg.clone())
                        .arg(arg!(--"demo" "Enable demo mode (for testing without a real device)")),
                )
                .subcommand(
                    Command::new("remove")
                        .about("Remove a paired device")
                        .alias("delete")
                        .alias("rm")
                        .arg(mac_address_arg.clone().required(true))
                )
                .subcommand(
                    Command::new("list")
                        .about("List all paired devices")
                        .alias("ls")
                        .arg(json_arg.clone())
                ),
        )
        .subcommand(
            Command::new("device")
                .about("Interact with a paired device")
                .alias("dev")
                .arg(mac_address_arg.clone())
                .subcommand_required(true)
                .after_help(
                    "Examples:\n  \
                    openscq30 dev -a AA:BB:CC:DD:EE:FF list-settings\n  \
                    openscq30 dev -a AA:BB:CC:DD:EE:FF setting --get batteryLevel\n  \
                    openscq30 dev -a AA:BB:CC:DD:EE:FF setting --set ambientSoundMode=NoiseCanceling"
                )
                .subcommand(
                    Command::new("list-settings")
                        .about("List all available settings for the device")
                        .alias("ls")
                        .arg(arg!(--"no-categories" "Don't display category headers"))
                        .arg(arg!(--"no-extended-info" "Don't display setting information, only IDs"))
                        .arg(json_arg.clone())
                )
                .subcommand(
                    Command::new("setting")
                        .about("Get or set device settings")
                        .alias("set")
                        .alias("get")
                        .after_help(
                            "Setting Types:\n  \
                            toggle:       --set wearingDetection=true\n  \
                            select:       --set ambientSoundMode=NoiseCanceling\n  \
                            equalizer:    --set volumeAdjustments=0,0,0,0,0,0,0,0\n  \
                            range:        --set customNoiseCanceling=5\n  \
                            modifiable:   --set customEqualizerProfile=+NewProfile\n  \
                            action:       --set resetButtonsToDefault"
                        )
                        .arg(
                            arg!(-g --get <SETTING_ID> "Get the value of a setting")
                                .action(ArgAction::Append),
                        )
                        .arg(
                            arg!(-s --set <"SETTING_ID=VALUE"> "Set the value of a setting")
                                .action(ArgAction::Append),
                        )
                        .arg(json_arg.clone()),
                )
        )
        .subcommand(
            Command::new("scan")
                .about("Scan for available Soundcore devices")
                .arg(device_model_arg)
                .arg(json_arg)
                .after_help(
                    "Examples:\n  \
                    openscq30 scan -m SoundcoreA3040\n  \
                    openscq30 scan -m SoundcoreA3040 --json"
                )
        )
        .subcommand(
            Command::new("completions")
                .about("Generate shell completions")
                .after_help(
                    "Examples:\n  \
                    openscq30 completions -s bash > ~/.local/share/bash-completion/completions/openscq30\n  \
                    openscq30 completions -s zsh > ~/.local/share/zsh/site-functions/_openscq30\n  \
                    openscq30 completions -s fish > ~/.config/fish/completions/openscq30.fish"
                )
                .arg(
                    arg!(-s --shell <SHELL> "Target shell for completions")
                        .required(true)
                        .value_parser(value_parser!(clap_complete::Shell))
                )
        )
}

pub async fn handle(matches: &ArgMatches) -> anyhow::Result<()> {
    match matches.subcommand().unwrap() {
        ("paired-devices", matches) => pair::handle(matches).await?,
        ("device", matches) => device::handle(matches).await?,
        ("scan", matches) => scan::handle(matches).await?,
        ("completions", matches) => completions::handle(matches)?,
        _ => (),
    }
    Ok(())
}
