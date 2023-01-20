import styles from '@/styles/ComputerStore.module.css'
import {
  Container,
  InputAdornment,
  TextField,
  debounce,
  Button,
  ImageList,
  ImageListItem,
  ImageListItemBar,
  Chip,
  Box, Typography
} from "@mui/material";
import {Search, LocalShipping, Redeem} from "@mui/icons-material";
import {useCallback, useState, useEffect, ChangeEventHandler} from "react";
import axios from "axios";
import * as process from "process";

type Computer = {
  id: number;
  vendor: string;
  title: string;
  price: number;
  strikedPrice: number;
  imageUrl: string;
}

type SearchBarProps = {
  setSearchTerm: React.Dispatch<React.SetStateAction<string>>;
}

function SearchBar({setSearchTerm}: SearchBarProps) {

  const debouncedChangeHandler: ChangeEventHandler<HTMLTextAreaElement | HTMLInputElement> = useCallback(
    debounce(
      (e) => setSearchTerm(e.target.value),
      250
    ), []
  );

  return (
    <TextField
      className={styles["search-bar"]}
      onChange={debouncedChangeHandler}
      InputProps={{
        startAdornment: (
          <InputAdornment position="start">
            <Search/>
          </InputAdornment>
        ),
        size: "small",
        placeholder: "Search"
      }}
    />
  )
}

type SearchResultsProps = {
  computers: Computer[];
}

function SearchResults({computers}: SearchResultsProps) {
  function handleDealClick(): void {
    console.log('Viewed a deal')
  }

  function formatNumber(value: number): string {
    return parseFloat(String(value)).toFixed(2).toLocaleString()
  }

  return (
    <ImageList cols={4}>
      {computers.map((computer: Computer) => (
        <ImageListItem key={computer.id} className={styles["computer-list-item"]}>
          <img
            className={styles["computer-image"]}
            src={computer.imageUrl}
            loading="lazy"
          />
          <ImageListItemBar
            sx={{width: 200}}
            title={computer.vendor}
            subtitle={<div className={styles["computer-title"]}>{computer.title}</div>}
            position="below"
            className={styles["computer-list-item-bar"]}
          />
          <Typography className={styles["price"]}>
            {computer.strikedPrice && computer.price ? (
              <span className={styles["deal-price"]}>${formatNumber(computer.price)} <s className={styles["strike-price"]}>${formatNumber(computer.strikedPrice)}</s></span>
            ) : computer.price ? (
              <span>${formatNumber(computer.price)}</span>
            ) : (
              <span>Price Unavailable</span>
            )
            }
          </Typography>
          <span className={styles.freebies}><LocalShipping className={styles["freebie-icons"]}/> Free Shipping <Redeem className={styles["freebie-icons"]}/> Free Gift</span>
          <Chip label="VIEW DEAL" color="success" onClick={handleDealClick}/>
        </ImageListItem>
      ))}
    </ImageList>
  );
}

type ShowMoreProps = {
  computers: Computer[];
  setComputers: React.Dispatch<React.SetStateAction<Computer[]>>;
  nextPage: string | null;
  setNextPage: React.Dispatch<React.SetStateAction<string | null>>;
}

function ShowMoreButton({computers, setComputers, nextPage, setNextPage}: ShowMoreProps) {
  function handleClick() {
    if (nextPage) {
      let newComputers = computers.slice()
      axios(nextPage)
        .then(response => {
          newComputers.concat(response.data.results)
          setComputers(newComputers.concat(response.data.results))
          setNextPage(response.data.next)
        })
        .catch(function (error) {
          console.log(error);
        })
    }
  }

  return (nextPage) ?
    <Box textAlign='center'><Button color="success" onClick={handleClick}>Show More</Button></Box> : <></>
}

type NumberOfResultsProps = {
  computers: Computer[];
  totalCount: number;
}

function NumberOfResults({computers, totalCount}: NumberOfResultsProps) {
  return (
    <div className={styles["number-results"]}>
      <Typography className={styles["results-label"]} variant="h4">Results</Typography>
      <Typography className={styles["showing-label"]}>Showing {computers.length} of {totalCount}</Typography>
    </div>
  )
}

export default function Computerstore() {
  const [computers, setComputers] = useState<Computer[]>([])
  const [searchTerm, setSearchTerm] = useState<string>("")
  const [nextPage, setNextPage] = useState<string | null>(null)
  const [totalCount, setTotalCount] = useState<number>(0)
  const apiHost: string = (process.env.NODE_ENV === 'production') ? '' : 'http://localhost:8000'

  useEffect(() => {
    axios(`${apiHost}/api/v1/search/?search_term=${searchTerm}`)
      .then(response => {
        setComputers(response.data.results)
        setNextPage(response.data.next)
        setTotalCount(response.data.count)
      })
      .catch(function (error) {
        console.log(error);
      })
  }, [searchTerm, apiHost])

  return (
    <div className={styles.body}>
      <div className={styles.header}>
        <Container maxWidth="lg">
          <SearchBar setSearchTerm={setSearchTerm}/>
        </Container>
      </div>
      <Container maxWidth="lg">
        <NumberOfResults computers={computers} totalCount={totalCount}/>
        <SearchResults computers={computers}/>
        <ShowMoreButton computers={computers} setComputers={setComputers} nextPage={nextPage}
                        setNextPage={setNextPage}/>
      </Container>
      <div className={styles.footer}></div>
    </div>

  );
}