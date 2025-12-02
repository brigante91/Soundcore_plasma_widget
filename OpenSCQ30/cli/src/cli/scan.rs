use clap::ArgMatches;
use openscq30_lib::{DeviceModel, connection::ConnectionDescriptor};
use serde::Serialize;
use tabled::{Table, Tabled};

use crate::openscq30_session;

pub async fn handle(matches: &ArgMatches) -> anyhow::Result<()> {
    let session = openscq30_session().await?;
    let model = matches.get_one::<DeviceModel>("model").unwrap().to_owned();

    let devices = session.list_devices(model).await?;

    if matches.get_flag("json") {
        let json_devices: Vec<JsonConnectionDescriptor> =
            devices.into_iter().map(Into::into).collect();
        println!("{}", serde_json::to_string_pretty(&json_devices)?);
    } else {
        let table_items: Vec<ConnectionDescriptorTableItem> =
            devices.into_iter().map(Into::into).collect();
        let mut table = Table::new(table_items);
        crate::fmt::apply_tabled_settings(&mut table);
        println!("{table}");
    }

    Ok(())
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct JsonConnectionDescriptor {
    name: String,
    mac_address: String,
}

impl From<ConnectionDescriptor> for JsonConnectionDescriptor {
    fn from(desc: ConnectionDescriptor) -> Self {
        Self {
            name: desc.name,
            mac_address: desc.mac_address.to_string(),
        }
    }
}

#[derive(Tabled)]
struct ConnectionDescriptorTableItem {
    #[tabled(rename = "Name")]
    name: String,
    #[tabled(rename = "MAC Address")]
    mac_address: String,
}

impl From<ConnectionDescriptor> for ConnectionDescriptorTableItem {
    fn from(desc: ConnectionDescriptor) -> Self {
        Self {
            name: desc.name,
            mac_address: desc.mac_address.to_string(),
        }
    }
}

