//! A minimal example that outputs "hello world"

use bevy::prelude::*;

pub fn main() {
    App::new().add_systems(Update, hello_world_system).run();
}

fn hello_world_system() {
    println!("hello world");
}