

#[macro_export]
macro_rules! group_context {
    ($g:expr) => {{
        context! {
            id: $g.id,
            name: $g.name,
            description: $g.description,
            // image: g.image,
        }
    }};
}

#[macro_export]
macro_rules! post_context {
    ($p:expr) => {{
        let re = regex::Regex::new(r"[^\w]").unwrap();
        let post_link = format!("/post/{}/{}", $p.id, re.replace_all(&$p.title().replace(" ", "_"), ""));

        context! {
            title: $p.title,
            link: $p.link,
            post_link: post_link,
            content: markdown::to_html($p.content.unwrap_or("".to_string()).as_str())
        }
    }};
}

#[macro_export]
macro_rules! home_page {
    ($conn:expr) => {{
        match get_server_configuration($conn)
        .unwrap()
        .server_info
        .unwrap()
        .web_user_interface()
    {
        WebUserInterface::FlutterWeb => "/home",
        WebUserInterface::HandlebarsTemplates => "/",
    }
    }}
}