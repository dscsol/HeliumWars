import styles from "./HomeHero.module.scss";
import logoIcon from "../media/logo_icon.svg";
import logoText from "../media/logo_text.svg";
import heroVideo from "../media/landing_video_high.mp4";
import linkDc from "../media/link_dc.svg";
import linkFb from "../media/link_fb.svg";
import linkIg from "../media/link_ig.svg";
import linkTele from "../media/link_tele.svg";
import linkWechat from "../media/link_wechat.svg";
import { useRef, useState } from "react";

function HomeHero() {
  const subEmailRef = useRef();
  const [isSubmit, setIsSubmit] = useState(false);
  const subscribeHandler = async (e) => {
    e.preventDefault();
    const enteredSubEmail = subEmailRef.current.value;
    console.log(enteredSubEmail);
    console.log(JSON.stringify(enteredSubEmail));

    const res = await fetch("http://localhost:8000/subscribe", {
      method: "POST",
      body: JSON.stringify(enteredSubEmail),
      headers: {
        "Content-Type": "application/json",
      },
    });
    const data = await res.json();
    setIsSubmit(true);
    console.log(data);
  };
  return (
    <div className={`${styles.container}`}>
      <nav className={styles.nav}>
        <img src={logoIcon} alt="logo" />
        <img src={logoText} alt="Helium Wars" />
      </nav>
      <section className={styles.hero}>
        <div className={styles.social}>
          <img src={linkDc} alt="discord" />
          <img src={linkFb} alt="facebook" />
          <img src={linkIg} alt="Instagram" />
          <img src={linkTele} alt="Telegram" />
          <img src={linkWechat} alt="Wechat" />
        </div>
        <div className={styles["video-container"]}>
          <video src={heroVideo} autoPlay loop muted />
        </div>
      </section>
      <footer className={styles.footer}>
        <div className={styles["subscribe-container"]}>
          <form onSubmit={subscribeHandler}>
            <input
              type="email"
              placeholder="Your Email Address..."
              ref={subEmailRef}
            />
            <button disabled={isSubmit}>
              {isSubmit ? "Subscribed!" : "Subscribe"}
            </button>
          </form>
        </div>
        <h2>COMING SOON...</h2>
      </footer>
    </div>
  );
}

export default HomeHero;
