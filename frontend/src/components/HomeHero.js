import styles from "./HomeHero.module.scss";
import logoIcon from "../media/logo_icon.svg";
import logoText from "../media/logo_text.svg";
import heroVideo from "../media/landing_video_high.mp4";
import linkDc from "../media/link_dc.svg";
import linkFb from "../media/link_fb.svg";
import linkIg from "../media/link_ig.svg";
import linkTele from "../media/link_tele.svg";
import linkWechat from "../media/link_wechat.svg";

function HomeHero() {
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
        <p>COMING SOON...</p>
      </footer>
    </div>
  );
}

export default HomeHero;
